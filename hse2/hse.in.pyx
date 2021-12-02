# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2020-2021 Micron Technology, Inc. All rights reserved.

import errno
import os
import pathlib
cimport cython
cimport limits
from enum import Enum, IntFlag, unique
from types import TracebackType
from typing import List, Optional, Tuple, Dict, Iterator, Type, Union, Iterable, SupportsBytes
from libc.stdlib cimport malloc, free


# Throughout these bindings, you will see C pointers be set to NULL after their
# destruction. Please continue to follow this pattern as the HSE C code does
# not do this. We use NULL checks to protect against double free
# issues within the Python bindings.

# bytes(<bytes object>) returns the original bytes object. It is not a copy.


def to_bytes(obj: Optional[Union[str, bytes, SupportsBytes]]) -> bytes:
    if obj is None:
        return None

    if isinstance(obj, str):
        return obj.encode()

    return bytes(obj)


cdef char **to_paramv(tuple params) except NULL:
    cdef char **paramv = <char **>malloc(len(params) * sizeof(char *))
    if not paramv:
        raise MemoryError()
    else:
        for i, param in enumerate(params):
            assert isinstance(param, str)
            paramv[i] = <char *>PyUnicode_AsUTF8(param)
            if not paramv[i]:
                return NULL

    return paramv


def init(config: Optional[Union[str, os.PathLike[str]]] = None, *params: str) -> None:
    """
    @SUB@ hse.init
    """
    config_bytes = os.fspath(config).encode() if config else None
    cdef const char *config_addr = <char *>config_bytes if config_bytes else NULL
    cdef char **paramv = to_paramv(params) if len(params) > 0 else NULL

    cdef hse_err_t err = hse_init(config_addr, len(params), <const char * const*>paramv)

    if paramv:
        free(paramv)
    if err != 0:
        raise HseException(err)


def fini() -> None:
    """
    @SUB@ hse.fini
    """
    hse_fini()


def param(str param) -> str:
    """
    @SUB@ hse.param
    """
    param_bytes = param.encode() if param else None
    cdef const char *param_addr = <char *>param_bytes
    cdef char *buf = NULL
    cdef size_t needed_sz = 0

    cdef hse_err_t err = 0
    with nogil:
        err = hse_param_get(param_addr, NULL, 0, &needed_sz)
        if err == 0:
            buf = <char *>malloc(needed_sz + 1)
            if not buf:
                raise MemoryError()
            err = hse_param_get(param_addr, buf, needed_sz + 1, NULL)

    try:
        if err != 0:
            raise HseException(err)

        return buf.decode()
    finally:
        free(buf)


class HseException(Exception):
    """
    @SUB@ hse.HseException
    """
    def __init__(self, hse_err_t returncode):
        self.returncode = hse_err_to_errno(returncode)
        cdef size_t needed_sz = 0
        needed_sz = hse_strerror(returncode, NULL, 0)
        cdef char *buf = <char *>malloc(needed_sz + 1)
        hse_strerror(returncode, buf, needed_sz + 1)
        self.message = buf.decode()
        free(buf)

    def __str__(self):
        return self.message


@unique
class KvdbSyncFlag(IntFlag):
    """
    @SUB@ hse.KvdbSyncFlag
    """
    ASYNC = HSE_KVDB_SYNC_ASYNC

IF HSE_PYTHON_EXPERIMENTAL == 1:
    @unique
    class KvdbCompactFlag(IntFlag):
        CANCEL = HSE_KVDB_COMPACT_CANCEL
        SAMP_LWM = HSE_KVDB_COMPACT_SAMP_LWM


@unique
class Mclass(Enum):
    """
    @SUB@ hse.Mclass
    """
    CAPACITY = HSE_MCLASS_CAPACITY
    STAGING = HSE_MCLASS_STAGING
    PMEM = HSE_MCLASS_PMEM

    def __str__(self) -> str:
        return hse_mclass_name_get(self.value).decode()


cdef class MclassInfo:
    """
    @SUB@ hse.MclassInfo
    """

    @property
    def allocated_bytes(self) -> int:
        """
        @SUB@ hse.MclassInfo.allocated_bytes
        """
        return self._c_hse_mclass_info.mi_allocated_bytes

    @property
    def used_bytes(self) -> int:
        """
        @SUB@ hse.MclassInfo.used_bytes
        """
        return self._c_hse_mclass_info.mi_used_bytes

    @property
    def path(self) -> pathlib.Path:
        """
        @SUB@ hse.MclassInfo.path
        """
        return pathlib.Path(self._c_hse_mclass_info.mi_path.decode())


cdef class Kvdb:
    def __cinit__(self, kvdb_home: Union[str, os.PathLike[str]], *params: str):
        self._c_hse_kvdb = NULL

        kvdb_home_bytes = os.fspath(kvdb_home).encode() if kvdb_home else None
        cdef const char *kvdb_home_addr = <char *>kvdb_home_bytes if kvdb_home_bytes else NULL
        cdef char **paramv = to_paramv(params) if len(params) > 0 else NULL

        err = hse_kvdb_open(kvdb_home_addr, len(params), <const char * const*>paramv, &self._c_hse_kvdb)
        free(paramv)
        if err != 0:
            raise HseException(err)

    @property
    def home(self) -> pathlib.Path:
        """
        @SUB@ hse.Kvdb.home
        """
        return pathlib.Path(hse_kvdb_home_get(self._c_hse_kvdb).decode())

    def close(self) -> None:
        """
        @SUB@ hse.Kvdb.close
        """
        if not self._c_hse_kvdb:
            return

        cdef hse_err_t err = hse_kvdb_close(self._c_hse_kvdb)
        if err != 0:
            raise HseException(err)
        self._c_hse_kvdb = NULL

    @staticmethod
    def create(kvdb_home: Union[str, os.PathLike[str]], *params: str) -> None:
        """
        @SUB@ hse.Kvdb.create
        """
        kvdb_home_bytes = os.fspath(kvdb_home).encode() if kvdb_home else None
        cdef const char *kvdb_home_addr = <char *>kvdb_home_bytes if kvdb_home_bytes else NULL
        cdef char **paramv = to_paramv(params) if len(params) > 0 else NULL

        cdef hse_err_t err = hse_kvdb_create(kvdb_home_addr, len(params), <const char * const*>paramv)
        free(paramv)
        if err != 0:
            raise HseException(err)

    @staticmethod
    def drop(kvdb_home: Union[str, os.PathLike[str]]) -> None:
        """
        @SUB@ hse.Kvdb.drop
        """
        kvdb_home_bytes = os.fspath(kvdb_home).encode() if kvdb_home else None
        cdef const char *kvdb_home_addr = <char *>kvdb_home_bytes if kvdb_home_bytes else NULL

        cdef hse_err_t err = hse_kvdb_drop(kvdb_home_addr)
        if err != 0:
            raise HseException(err)

    @staticmethod
    def open(kvdb_home: Union[str, os.PathLike[str]], *params: str) -> Kvdb:
        """
        @SUB@ hse.Kvdb.open
        """
        return Kvdb(kvdb_home, *params)

    @property
    def kvs_names(self) -> List[str]:
        """
        @SUB@ hse.Kvdb.kvs_names
        """
        cdef size_t namec = 0
        cdef char **namev = NULL
        cdef hse_err_t err = hse_kvdb_kvs_names_get(self._c_hse_kvdb, &namec, &namev)
        if err != 0:
            raise HseException(err)

        result = []
        for i in range(namec):
            result.append(namev[i].decode())

        hse_kvdb_kvs_names_free(self._c_hse_kvdb, namev)

        return result

    def kvs_create(self, str name, *params: str) -> None:
        """
        @SUB@ hse.Kvdb.kvs_create
        """
        name_bytes = name.encode() if name else None
        cdef const char *name_addr = <char *>name_bytes if name_bytes else NULL
        cdef char **paramv = to_paramv(params) if len(params) > 0 else NULL

        cdef hse_err_t err = hse_kvdb_kvs_create(
            self._c_hse_kvdb, name_addr, len(params),
            <const char *const *>paramv)
        free(paramv)
        if err != 0:
            raise HseException(err)

    def kvs_drop(self, str kvs_name) -> None:
        """
        @SUB@ hse.Kvdb.kvs_drop
        """
        cdef hse_err_t err = hse_kvdb_kvs_drop(self._c_hse_kvdb, kvs_name.encode())
        if err != 0:
            raise HseException(err)

    def kvs_open(self, str kvs_name, *params: str) -> Kvs:
        """
        @SUB@ hse.Kvdb.kvs_open
        """
        return Kvs(self, kvs_name, *params)

    def param(self, str param) -> str:
        """
        @SUB@ hse.Kvdb.param
        """
        param_bytes = param.encode() if param else None
        cdef const char *param_addr = <char *>param_bytes
        cdef char *buf = NULL
        cdef size_t needed_sz = 0

        cdef hse_err_t err = 0
        with nogil:
            err = hse_kvdb_param_get(self._c_hse_kvdb, param_addr, NULL, 0, &needed_sz)
            if err == 0:
                buf = <char *>malloc(needed_sz + 1)
                if not buf:
                    raise MemoryError()
                err = hse_kvdb_param_get(self._c_hse_kvdb, param_addr, buf, needed_sz + 1, NULL)

        try:
            if err != 0:
                raise HseException(err)

            return buf.decode()
        finally:
            free(buf)

    def sync(self, flags: Optional[KvdbSyncFlag] = None) -> None:
        """
        @SUB@ hse.Kvdb.sync
        """
        cdef unsigned int cflags = int(flags) if flags else 0
        cdef hse_err_t err = 0
        with nogil:
            err = hse_kvdb_sync(self._c_hse_kvdb, cflags)
        if err != 0:
            raise HseException(err)

    def mclass_info(self, mclass: Mclass) -> MclassInfo:
        """
        @SUB@ hse.Kvdb.mclass_info
        """
        info = MclassInfo()
        cdef hse_err_t err = 0
        cdef hse_mclass value = mclass.value
        with nogil:
            err = hse_kvdb_mclass_info_get(
                self._c_hse_kvdb, value, &info._c_hse_mclass_info)
        if err != 0:
            raise HseException(err)

        return info

    IF HSE_PYTHON_EXPERIMENTAL == 1:
        def compact(self, flags: Optional[KvdbCompactFlag] = None) -> None:
            """
            @SUB@ hse.Kvdb.compact
            """
            cdef unsigned int cflags = int(flags) if flags else 0

            cdef hse_err_t err = 0
            with nogil:
                err = hse_kvdb_compact(self._c_hse_kvdb, cflags)
            if err != 0:
                raise HseException(err)

        @property
        def compact_status(self) -> KvdbCompactStatus:
            """
            @SUB@ hse.Kvdb.compact_status
            """
            status: KvdbCompactStatus = KvdbCompactStatus()
            cdef hse_err_t err = 0
            with nogil:
                err = hse_kvdb_compact_status_get(self._c_hse_kvdb, &status._c_hse_kvdb_compact_status)
            if err != 0:
                raise HseException(err)
            return status

    @staticmethod
    def storage_add(kvdb_home: Union[str, os.PathLike[str]], *params: str) -> None:
        """
        @SUB@ hse.Kvdb.storage_add
        """
        kvdb_home_bytes = os.fspath(kvdb_home).encode() if kvdb_home else None
        cdef const char *kvdb_home_addr = <char *>kvdb_home_bytes if kvdb_home_bytes else NULL
        cdef size_t paramc = len(params)
        cdef char **paramv = to_paramv(params) if paramc > 0 else NULL
        cdef hse_err_t err = 0

        with nogil:
            err = hse_kvdb_storage_add(kvdb_home_addr, paramc, <const char * const*>paramv)

        free(paramv)
        if err != 0:
            raise HseException(err)

    def transaction(self) -> KvdbTransaction:
        """
        @SUB@ hse.Kvdb.transaction
        """
        txn = KvdbTransaction(self)

        return txn


@unique
class KvsPutFlag(IntFlag):
    """
    @SUB@ hse.KvsPutFlag
    """
    PRIO = HSE_KVS_PUT_PRIO
    VCOMP_OFF = HSE_KVS_PUT_VCOMP_OFF


@unique
class CursorCreateFlag(IntFlag):
    """
    @SUB@ hse.CursorCreateFlag
    """
    REV = HSE_CURSOR_CREATE_REV


IF HSE_PYTHON_EXPERIMENTAL == 1:
    @unique
    class KvsPfxProbeCnt(Enum):
        """
        @SUB@ hse.KvsPfxProbeCnt
        """
        ZERO = HSE_KVS_PFX_FOUND_ZERO
        ONE = HSE_KVS_PFX_FOUND_ONE
        MUL = HSE_KVS_PFX_FOUND_MUL


cdef class Kvs:
    def __cinit__(self, Kvdb kvdb, str name, *params: str):
        self._c_hse_kvs = NULL

        name_bytes = name.encode() if name else None
        cdef const char *name_addr = <char *>name_bytes if name_bytes else NULL
        cdef char **paramv = to_paramv(params) if len(params) > 0 else NULL

        cdef hse_err_t err = hse_kvdb_kvs_open(kvdb._c_hse_kvdb, name_addr, len(params),
            <const char * const*>paramv, &self._c_hse_kvs)
        free(paramv)
        if err != 0:
            raise HseException(err)

    @property
    def name(self) -> str:
        """
        @SUB@ hse.Kvs.name
        """
        return hse_kvs_name_get(self._c_hse_kvs).decode()

    def close(self) -> None:
        """
        @SUB@ hse.Kvs.close
        """
        if not self._c_hse_kvs:
            return

        cdef hse_err_t err = hse_kvdb_kvs_close(self._c_hse_kvs)
        if err != 0:
            raise HseException(err)
        self._c_hse_kvs = NULL

    def param(self, str param) -> str:
        """
        @SUB@ hse.Kvs.param
        """
        param_bytes = param.encode() if param else None
        cdef const char *param_addr = <char *>param_bytes
        cdef char *buf = NULL
        cdef size_t needed_sz = 0

        cdef hse_err_t err = 0
        with nogil:
            err = hse_kvs_param_get(self._c_hse_kvs, param_addr, NULL, 0, &needed_sz)
            if err == 0:
                buf = <char *>malloc(needed_sz + 1)
                if not buf:
                    raise MemoryError()
                err = hse_kvs_param_get(self._c_hse_kvs, param_addr, buf, needed_sz + 1, NULL)

        try:
            if err != 0:
                raise HseException(err)

            return buf.decode()
        finally:
            free(buf)

    def put(
            self,
            key: Union[str, bytes, SupportsBytes],
            value: Optional[Union[str, bytes, SupportsBytes]],
            KvdbTransaction txn=None,
            flags: Optional[KvsPutFlag]=None,
        ) -> None:
        """
        @SUB@ hse.Kvs.put
        """
        cdef unsigned int cflags = int(flags) if flags else 0
        cdef hse_kvdb_txn *txn_addr = NULL
        cdef const void *key_addr = NULL
        cdef size_t key_len = 0
        cdef const void *value_addr = NULL
        cdef size_t value_len = 0

        cdef const unsigned char [:]key_view = to_bytes(key)
        cdef const unsigned char [:]value_view = to_bytes(value)

        if txn:
            txn_addr = txn._c_hse_kvdb_txn
        if key_view is not None:
            key_addr = &key_view[0]
            key_len = key_view.shape[0]
        if value_view is not None:
            value_addr = &value_view[0]
            value_len = value_view.shape[0]

        cdef hse_err_t err = 0
        with nogil:
            err = hse_kvs_put(self._c_hse_kvs, cflags, txn_addr, key_addr, key_len, value_addr, value_len)
        if err != 0:
            raise HseException(err)

    def get(
            self,
            key: Union[str, bytes, SupportsBytes],
            KvdbTransaction txn=None,
            unsigned char [:]buf=bytearray(limits.HSE_KVS_VALUE_LEN_MAX),
        ) -> Tuple[Optional[bytes], int]:
        """
        @SUB@ hse.Kvs.get
        """
        cdef unsigned int cflags = 0
        cdef hse_kvdb_txn *txn_addr = NULL
        cdef const void *key_addr = NULL
        cdef size_t key_len = 0
        cdef void *buf_addr = NULL
        cdef size_t buf_len = 0

        cdef const unsigned char [:]key_view = to_bytes(key)

        if txn:
            txn_addr = txn._c_hse_kvdb_txn
        if key_view is not None:
            key_addr = &key_view[0]
            key_len = key_view.shape[0]
        if buf is not None:
            buf_addr = &buf[0]
            buf_len = buf.shape[0]

        cdef cbool found = False
        cdef size_t value_len = 0
        cdef hse_err_t err = 0
        with nogil:
            err = hse_kvs_get(self._c_hse_kvs, cflags, txn_addr, key_addr,
                key_len, &found, buf_addr, buf_len, &value_len)
        if err != 0:
            raise HseException(err)
        if not found:
            return None, 0

        if buf is None:
            return None, value_len

        if value_len < len(buf):
            return bytes(buf)[:value_len], value_len

        return bytes(buf), value_len

    def delete(self, key: Union[str, bytes, SupportsBytes], KvdbTransaction txn=None) -> None:
        """
        @SUB@ hse.Kvs.delete
        """
        cdef unsigned int cflags = 0
        cdef hse_kvdb_txn *txn_addr = NULL
        cdef const void *key_addr = NULL
        cdef size_t key_len = 0

        cdef const unsigned char [:]key_view = to_bytes(key)

        if txn:
            txn_addr = txn._c_hse_kvdb_txn
        if key_view is not None:
            key_addr = &key_view[0]
            key_len = key_view.shape[0]

        cdef hse_err_t err = 0
        with nogil:
            err = hse_kvs_delete(self._c_hse_kvs, cflags, txn_addr, key_addr, key_len)
        if err != 0:
            raise HseException(err)

    def prefix_delete(self, pfx: Union[str, bytes], txn: KvdbTransaction=None) -> None:
        """
        @SUB@ hse.Kvs.prefix_delete
        """
        cdef unsigned int cflags = 0
        cdef hse_kvdb_txn *txn_addr = NULL
        cdef const void *pfx_addr = NULL
        cdef size_t pfx_len = 0

        cdef const unsigned char[:] pfx_view = to_bytes(pfx)

        if txn:
            txn_addr = txn._c_hse_kvdb_txn
        if pfx_view is not None:
            pfx_addr = &pfx_view[0]
            pfx_len = pfx_view.shape[0]

        cdef hse_err_t err = 0
        with nogil:
            err = hse_kvs_prefix_delete(self._c_hse_kvs, cflags, txn_addr, pfx_addr, pfx_len)
        if err != 0:
            raise HseException(err)

    IF HSE_PYTHON_EXPERIMENTAL == 1:
        def prefix_probe(
            self,
            pfx: Union[str, bytes],
            unsigned char [:]key_buf=bytearray(limits.HSE_KVS_KEY_LEN_MAX),
            unsigned char [:]value_buf=bytearray(limits.HSE_KVS_VALUE_LEN_MAX),
            KvdbTransaction txn=None,
        ) -> Tuple[KvsPfxProbeCnt, Optional[bytes], int, Optional[bytes], int]:
            """
            @SUB@ hse.Kvs.prefix_probe
            """
            cdef hse_kvdb_txn *txn_addr = NULL
            cdef const void *pfx_addr = NULL
            cdef size_t pfx_len = 0
            cdef hse_kvs_pfx_probe_cnt found = HSE_KVS_PFX_FOUND_ZERO
            cdef void *key_buf_addr = NULL
            cdef size_t key_buf_len = 0
            cdef size_t key_len = 0
            cdef void *value_buf_addr = NULL
            cdef size_t value_buf_len = 0
            cdef size_t value_len = 0

            cdef const unsigned char[:] pfx_view = to_bytes(pfx)

            if pfx_view is not None:
                pfx_addr = &pfx_view[0]
                pfx_len = pfx_view.shape[0]
            if key_buf is not None and len(key_buf) > 0:
                key_buf_addr = &key_buf[0]
                key_buf_len = len(key_buf)
            if value_buf is not None and len(value_buf) > 0:
                value_buf_addr = &value_buf[0]
                value_buf_len = len(value_buf)
            if txn:
                txn_addr = txn._c_hse_kvdb_txn

            cdef hse_err_t err = 0
            with nogil:
                err = hse_kvs_prefix_probe(self._c_hse_kvs, 0, txn_addr,
                    pfx_addr, pfx_len, &found, key_buf_addr, key_buf_len, &key_len,
                    value_buf_addr, value_buf_len, &value_len)
            if err != 0:
                raise HseException(err)
            if found == HSE_KVS_PFX_FOUND_ZERO:
                return KvsPfxProbeCnt.ZERO, None, 0, None, 0

            return (
                KvsPfxProbeCnt(found),
                bytes(key_buf)[:key_len] if key_buf is not None and key_len < len(key_buf) else key_buf,
                key_len,
                bytes(value_buf)[:value_len] if value_buf is not None and value_len < len(value_buf) else value_buf,
                value_len
            )

    def cursor(
        self,
        filt: Optional[Union[str, bytes]]=None,
        KvdbTransaction txn=None,
        flags: Optional[CursorCreateFlag]=None,
    ) -> KvsCursor:
        """
        @SUB@ hse.Kvs.cursor
        """
        cursor: KvsCursor = KvsCursor(
            self,
            filt,
            txn=txn,
            flags=flags,
        )

        return cursor


@unique
class KvdbTransactionState(Enum):
    """
    @SUB@ hse.KvdbTransactionState
    """
    INVALID = HSE_KVDB_TXN_INVALID
    ACTIVE = HSE_KVDB_TXN_ACTIVE
    COMMITTED = HSE_KVDB_TXN_COMMITTED
    ABORTED = HSE_KVDB_TXN_ABORTED


@cython.no_gc_clear
cdef class KvdbTransaction:
    """
    @SUB@ hse.KvdbTransaction
    """
    def __cinit__(self, Kvdb kvdb):
        self.kvdb = kvdb

        with nogil:
            self._c_hse_kvdb_txn = hse_kvdb_txn_alloc(kvdb._c_hse_kvdb)
        if not self._c_hse_kvdb_txn:
            raise MemoryError()

    def __dealloc__(self):
        if not self.kvdb._c_hse_kvdb:
            return
        if not self._c_hse_kvdb_txn:
            return

        with nogil:
            hse_kvdb_txn_free(self.kvdb._c_hse_kvdb, self._c_hse_kvdb_txn)
            self._c_hse_kvdb_txn = NULL

    def __enter__(self):
        self.begin()
        return self

    def __exit__(self, exc_type: Optional[Type[BaseException]], exc_val: Optional[BaseException], exc_tb: Optional[TracebackType]):
        # PEP-343: If exception occurred in with statement, abort transaction
        if exc_tb:
            self.abort()
            return

        if self.state == KvdbTransactionState.ACTIVE:
            self.commit()

        with nogil:
            hse_kvdb_txn_free(self.kvdb._c_hse_kvdb, self._c_hse_kvdb_txn)
            self._c_hse_kvdb_txn = NULL

    def begin(self) -> None:
        """
        @SUB@ hse.KvdbTransaction.begin
        """
        cdef hse_err_t err = 0
        with nogil:
            err = hse_kvdb_txn_begin(self.kvdb._c_hse_kvdb, self._c_hse_kvdb_txn)
        if err != 0:
            raise HseException(err)

    def commit(self) -> None:
        """
        @SUB@ hse.KvdbTransaction.commit
        """
        cdef hse_err_t err = 0
        with nogil:
            err = hse_kvdb_txn_commit(self.kvdb._c_hse_kvdb, self._c_hse_kvdb_txn)
        if err != 0:
            raise HseException(err)

    def abort(self) -> None:
        """
        @SUB@ hse.KvdbTransaction.abort
        """
        cdef hse_err_t err = 0
        with nogil:
            err = hse_kvdb_txn_abort(self.kvdb._c_hse_kvdb, self._c_hse_kvdb_txn)
        if err != 0:
            raise HseException(err)

    @property
    def state(self) -> KvdbTransactionState:
        """
        @SUB@ hse.KvdbTransaction.state
        """
        cdef hse_kvdb_txn_state state = HSE_KVDB_TXN_INVALID
        with nogil:
            state = hse_kvdb_txn_state_get(self.kvdb._c_hse_kvdb, self._c_hse_kvdb_txn)
        return KvdbTransactionState(state)


cdef class KvsCursor:
    def __cinit__(
        self,
        Kvs kvs,
        filt: Optional[Union[str, bytes]]=None,
        KvdbTransaction txn=None,
        flags: Optional[CursorCreateFlag]=None,
    ):
        self._eof = False

        cdef unsigned int cflags = int(flags) if flags else 0
        cdef hse_kvdb_txn *txn_addr = NULL
        cdef const void *filt_addr = NULL
        cdef size_t filt_len = 0

        cdef const unsigned char[:] filt_view = to_bytes(filt)

        if txn:
            txn_addr = txn._c_hse_kvdb_txn
        if filt_view is not None:
            filt_addr = &filt_view[0]
            filt_len = filt_view.shape[0]

        with nogil:
            err = hse_kvs_cursor_create(
                kvs._c_hse_kvs,
                cflags,
                txn_addr,
                filt_addr,
                filt_len,
                &self._c_hse_kvs_cursor
            )
        if err != 0:
            raise HseException(err)

    def __dealloc__(self):
        if self._c_hse_kvs_cursor:
            with nogil:
                hse_kvs_cursor_destroy(self._c_hse_kvs_cursor)
            self._c_hse_kvs_cursor = NULL

    def __enter__(self):
        return self

    def __exit__(self, exc_type: Optional[Type[BaseException]], exc_val: Optional[BaseException], exc_tb: Optional[TracebackType]):
        self.destroy()

    def destroy(self):
        """
        @SUB@ hse.KvsCursor.destroy
        """
        if self._c_hse_kvs_cursor:
            with nogil:
                hse_kvs_cursor_destroy(self._c_hse_kvs_cursor)
            self._c_hse_kvs_cursor = NULL

    def items(self) -> Iterator[Tuple[bytes, Optional[bytes]]]:
        """
        @SUB@ hse.KvsCursor.items
        """
        def _iter():
            while True:
                key, val = self.read()
                if not self._eof:
                    yield key, val
                else:
                    return

        return _iter()

    def update_view(self) -> None:
        """
        @SUB@ hse.KvsCursor.update_view
        """
        cdef unsigned int cflags = 0

        cdef hse_err_t err = 0
        with nogil:
            err = hse_kvs_cursor_update_view(self._c_hse_kvs_cursor, cflags)
        if err != 0:
            raise HseException(err)

    def seek(self, key: Union[str, bytes, SupportsBytes]) -> Optional[bytes]:
        """
        @SUB@ hse.KvsCursor.seek
        """
        cdef unsigned int cflags = 0
        cdef const void *key_addr = NULL
        cdef size_t key_len = 0

        cdef const unsigned char [:]key_view = to_bytes(key)

        if key_view is not None:
            key_addr = &key_view[0]
            key_len = key_view.shape[0]

        cdef const void *found = NULL
        cdef size_t found_len = 0
        cdef hse_err_t err = 0
        with nogil:
            err = hse_kvs_cursor_seek(
                self._c_hse_kvs_cursor,
                cflags,
                key_addr,
                key_len,
                &found,
                &found_len
            )
        if err != 0:
            raise HseException(err)

        if not found:
            return None

        return (<char *>found)[:found_len]

    def seek_range(self, filt_min: Optional[Union[str, bytes, SupportsBytes]], filt_max: Optional[Union[str, bytes, SupportsBytes]]) -> Optional[bytes]:
        """
        @SUB@ hse.KvsCursor.seek_range
        """
        cdef unsigned int cflags = 0
        cdef const void *filt_min_addr = NULL
        cdef size_t filt_min_len = 0
        cdef const void *filt_max_addr = NULL
        cdef size_t filt_max_len = 0

        cdef const unsigned char[:] filt_min_view = to_bytes(filt_min)
        cdef const unsigned char[:] filt_max_view = to_bytes(filt_max)

        if filt_min_view is not None:
            filt_min_addr = &filt_min_view[0]
            filt_min_len = filt_min_view.shape[0]
        if filt_max_view is not None:
            filt_max_addr = &filt_max_view[0]
            filt_max_len = filt_max_view.shape[0]

        cdef const void *found = NULL
        cdef size_t found_len = 0
        cdef hse_err_t err = 0
        with nogil:
            err = hse_kvs_cursor_seek_range(
                self._c_hse_kvs_cursor,
                cflags,
                filt_min_addr,
                filt_min_len,
                filt_max_addr,
                filt_max_len,
                &found,
                &found_len
            )
        if err != 0:
            raise HseException(err)

        if not found:
            return None

        return (<char *>found)[:found_len]

    def read(self) -> Tuple[Optional[bytes], Optional[bytes]]:
        """
        @SUB@ hse.KvsCursor.read
        """
        cdef unsigned int cflags = 0
        cdef const void *key = NULL
        cdef const void *value = NULL
        cdef size_t key_len = 0
        cdef size_t value_len = 0
        cdef cbool eof = False
        cdef hse_err_t err = 0
        with nogil:
            err = hse_kvs_cursor_read(
                self._c_hse_kvs_cursor,
                cflags,
                &key,
                &key_len,
                &value,
                &value_len,
                &eof
            )
        if err != 0:
            raise HseException(err)

        self._eof = eof
        if eof:
            return None, None
        else:
            return (<char *>key)[:key_len], (<char *>value)[:value_len] if value else None

    @property
    def eof(self) -> bool:
        """
        @SUB@ hse.KvsCursor.eof
        """
        return self._eof


IF HSE_PYTHON_EXPERIMENTAL == 1:
    cdef class KvdbCompactStatus:
        """
        @SUB@ hse.KvdbCompactStatus
        """
        @property
        def samp_lwm(self) -> int:
            """
            @SUB@ hse.KvdbCompactStatus.samp_lwm
            """
            return self._c_hse_kvdb_compact_status.kvcs_samp_lwm

        @property
        def samp_hwm(self) -> int:
            """
            @SUB@ hse.KvdbCompactStatus.samp_hwm
            """
            return self._c_hse_kvdb_compact_status.kvcs_samp_hwm

        @property
        def samp_curr(self) -> int:
            """
            @SUB@ hse.KvdbCompactStatus.samp_curr
            """
            return self._c_hse_kvdb_compact_status.kvcs_samp_curr

        @property
        def active(self) -> int:
            """
            @SUB@ hse.KvdbCompactStatus.active
            """
            return self._c_hse_kvdb_compact_status.kvcs_active

        @property
        def canceled(self) -> int:
            """
            @SUB@ hse.KvdbCompactStatus.canceled
            """
            return self._c_hse_kvdb_compact_status.kvcs_canceled
