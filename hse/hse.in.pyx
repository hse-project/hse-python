# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2020-2021 Micron Technology, Inc. All rights reserved.

import errno
import os
cimport cython
cimport limits
from enum import Enum, IntFlag, unique
from types import TracebackType
from typing import List, Optional, Tuple, Dict, Iterator, Type, Union, Iterable
from libc.stdlib cimport malloc, free


# Throughout these bindings, you will see C pointers be set to NULL after their
# destruction. Please continue to follow this pattern as the HSE C code does
# not do this. We use NULL checks to protect against double free
# issues within the Python bindings.


def init(*params: str) -> None:
    """
    @SUB@ hse.init.__doc__
    """
    cdef char **paramv = to_paramv(params) if len(params) > 0 else NULL
    cdef hse_err_t err = hse_init(len(params), <const char * const*>paramv)
    if paramv:
        free(paramv)
    if err != 0:
        raise KvdbException(err)


def fini() -> None:
    """
    @SUB@ hse.fini.__doc__
    """
    hse_fini()


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


class KvdbException(Exception):
    """
    @SUB@ hse.KvdbException.__doc__
    """
    def __init__(self, hse_err_t returncode):
        self.returncode = hse_err_to_errno(returncode)
        IF HSE_PYTHON_DEBUG != 0:
            cdef char buf[256]
            self.message = hse_err_to_string(returncode, buf, 256, NULL).decode()
        ELSE:
            self.message = os.strerror(self.returncode)

    def __str__(self):
        return self.message


cdef class Kvdb:
    def __cinit__(self, home: Optional[os.PathLike[str]], *params: str):
        self._c_hse_kvdb = NULL

        home_bytes = os.fspath(home).encode() if home else None
        cdef const char *home_addr = <char *>home_bytes if home_bytes else NULL
        cdef char **paramv = to_paramv(params) if len(params) > 0 else NULL

        err = hse_kvdb_open(home_addr, len(params), <const char * const*>paramv, &self._c_hse_kvdb)
        if paramv:
            free(paramv)
        if err != 0:
            raise KvdbException(err)

    def __dealloc__(self):
        self.close()

    def close(self) -> None:
        """
        @SUB@ hse.Kvdb.close.__doc__
        """
        if not self._c_hse_kvdb:
            return

        cdef hse_err_t err = hse_kvdb_close(self._c_hse_kvdb)
        if err != 0:
            raise KvdbException(err)
        self._c_hse_kvdb = NULL

    @staticmethod
    def create(home: Optional[os.PathLike[str]]=None, *params: str) -> None:
        """
        @SUB@ hse.Kvdb.create.__doc__
        """
        home_bytes = os.fspath(home).encode() if home else None
        cdef const char *home_addr = <char *>home_bytes if home_bytes else NULL
        cdef char **paramv = to_paramv(params) if len(params) > 0 else NULL

        cdef hse_err_t err = hse_kvdb_create(home_addr, len(params), <const char * const*>paramv)
        if paramv:
            free(paramv)
        if err != 0:
            raise KvdbException(err)

    @staticmethod
    def drop(home: Optional[os.PathLike[str]]=None, *params: str) -> None:
        """
        @SUB@ hse.Kvdb.drop.__doc__
        """
        home_bytes = os.fspath(home).encode() if home else None
        cdef const char *home_addr = <char *>home_bytes if home_bytes else NULL
        cdef char **paramv = to_paramv(params) if len(params) > 0 else NULL

        cdef hse_err_t err = hse_kvdb_drop(home_addr, len(params), <const char * const*>paramv)
        if paramv:
            free(paramv)
        if err != 0:
            raise KvdbException(err)

    @staticmethod
    def open(home: Optional[os.PathLike[str]]=None, *params: str) -> Kvdb:
        """
        @SUB@ hse.Kvdb.open.__doc__
        """
        return Kvdb(home, *params)

    @property
    def names(self) -> List[str]:
        """
        @SUB@ hse.Kvdb.names.__doc__
        """
        cdef unsigned int count = 0
        cdef char **kvs_list = NULL
        cdef hse_err_t err = hse_kvdb_get_names(self._c_hse_kvdb, &count, &kvs_list)
        if err != 0:
            raise KvdbException(err)
        if count > 0 and not kvs_list:
            raise MemoryError()

        result = []
        for i in range(count):
            result.append(kvs_list[i].decode())

        hse_kvdb_free_names(self._c_hse_kvdb, kvs_list)

        return result

    def kvs_create(self, str name, *params: str) -> None:
        """
        @SUB@ hse.Kvdb.kvs_create.__doc__
        """
        name_bytes = name.encode() if name else None
        cdef const char *name_addr = <char *>name_bytes if name_bytes else NULL
        cdef char **paramv = to_paramv(params) if len(params) > 0 else NULL

        cdef hse_err_t err = hse_kvdb_kvs_create(
            self._c_hse_kvdb, name_addr, len(params),
            <const char * const*>paramv)
        if err != 0:
            raise KvdbException(err)

    def kvs_drop(self, str kvs_name) -> None:
        """
        @SUB@ hse.Kvdb.kvs_drop.__doc__
        """
        cdef hse_err_t err = hse_kvdb_kvs_drop(self._c_hse_kvdb, kvs_name.encode())
        if err != 0:
            raise KvdbException(err)

    def kvs_open(self, str kvs_name, *params: str) -> Kvs:
        """
        @SUB@ hse.Kvdb.kvs_open.__doc__
        """
        return Kvs(self, kvs_name, *params)

    def sync(self) -> None:
        """
        @SUB@ hse.Kvdb.sync.__doc__
        """
        cdef hse_err_t err = 0
        with nogil:
            err = hse_kvdb_sync(self._c_hse_kvdb)
        if err != 0:
            raise KvdbException(err)

    def flush(self) -> None:
        """
        @SUB@ hse.Kvdb.flush.__doc__
        """
        cdef hse_err_t err = 0
        with nogil:
            err = hse_kvdb_flush(self._c_hse_kvdb)
        if err != 0:
            raise KvdbException(err)

    def compact(self, cancel: bool=False, samp_lwm: bool=False) -> None:
        """
        @SUB@ hse.Kvdb.compact.__doc__
        """
        cdef int flags = 0
        if cancel:
            flags |= HSE_KVDB_COMP_FLAG_CANCEL
        if samp_lwm:
            flags |= HSE_KVDB_COMP_FLAG_SAMP_LWM

        cdef hse_err_t err = 0
        with nogil:
            err = hse_kvdb_compact(self._c_hse_kvdb, flags)
        if err != 0:
            raise KvdbException(err)

    @property
    def compact_status(self) -> KvdbCompactStatus:
        """
        @SUB@ hse.Kvdb.compact_status.__doc__
        """
        status: KvdbCompactStatus = KvdbCompactStatus()
        cdef hse_err_t err = 0
        with nogil:
            err = hse_kvdb_compact_status_get(self._c_hse_kvdb, &status._c_hse_kvdb_compact_status)
        if err != 0:
            raise KvdbException(err)
        return status

    @property
    def storage_info(self) -> KvdbStorageInfo:
        """
        @SUB@ hse.Kvdb.storage_info.__doc__
        """
        info: KvdbStorageInfo = KvdbStorageInfo()
        cdef hse_err_t err = 0
        with nogil:
            err = hse_kvdb_storage_info_get(self._c_hse_kvdb, &info._c_hse_kvdb_storage_info)
        if err != 0:
            raise KvdbException(err)
        return info

    def transaction(self) -> Transaction:
        """
        @SUB@ hse.Kvdb.transaction.__doc__
        """
        txn = Transaction(self)

        return txn


@unique
class PutFlag(IntFlag):
    PRIORITY = HSE_FLAG_PUT_PRIORITY


@unique
class CursorFlag(IntFlag):
    REVERSE = HSE_FLAG_CURSOR_REVERSE
    STATIC_VIEW = HSE_FLAG_CURSOR_STATIC_VIEW
    BIND_TXN = HSE_FLAG_CURSOR_BIND_TXN


cdef class Kvs:
    def __cinit__(self, Kvdb kvdb, str name, *params: str):
        self._c_hse_kvs = NULL

        name_bytes = name.encode() if name else None
        cdef const char *name_addr = <char *>name_bytes if name_bytes else NULL
        cdef char **paramv = to_paramv(params) if len(params) > 0 else NULL

        cdef hse_err_t err = hse_kvdb_kvs_open(kvdb._c_hse_kvdb, name_addr, len(params),
            <const char * const*>paramv, &self._c_hse_kvs)
        if err != 0:
            raise KvdbException(err)

    def __dealloc__(self):
        self.close()

    def close(self) -> None:
        """
        @SUB@ hse.Kvs.close.__doc__
        """
        if not self._c_hse_kvs:
            return

        cdef hse_err_t err = hse_kvdb_kvs_close(self._c_hse_kvs)
        if err != 0:
            raise KvdbException(err)
        self._c_hse_kvs = NULL

    def put(
            self,
            const unsigned char [:]key,
            const unsigned char [:]value,
            Transaction txn=None,
            flags: PutFlag=0,
        ) -> None:
        """
        @SUB@ hse.Kvs.put.__doc__
        """
        cdef unsigned int cflags = int(flags)
        cdef hse_kvdb_txn *txn_addr = NULL
        cdef const void *key_addr = NULL
        cdef size_t key_len = 0
        cdef const void *value_addr = NULL
        cdef size_t value_len = 0

        if txn:
            txn_addr = txn._c_hse_kvdb_txn
        if key is not None:
            key_addr = &key[0]
            key_len = key.shape[0]
        if value is not None:
            value_addr = &value[0]
            value_len = value.shape[0]

        cdef hse_err_t err = 0
        with nogil:
            err = hse_kvs_put(self._c_hse_kvs, cflags, txn_addr, key_addr, key_len, value_addr, value_len)
        if err != 0:
            raise KvdbException(err)

    def get(
            self,
            const unsigned char [:]key,
            Transaction txn=None,
            unsigned char [:]buf=bytearray(limits.HSE_KVS_VLEN_MAX),
        ) -> Optional[bytes]:
        """
        @SUB@ hse.Kvs.get.__doc__
        """
        value, _ = self.get_with_length(key, txn=txn, buf=buf)
        return value

    def get_with_length(
            self,
            const unsigned char [:]key,
            Transaction txn=None,
            unsigned char [:]buf=bytearray(limits.HSE_KVS_VLEN_MAX),
        ) -> Tuple[Optional[bytes], int]:
        """
        @SUB@ hse.Kvs.get_with_length.__doc__
        """
        cdef unsigned int cflags = 0
        cdef hse_kvdb_txn *txn_addr = NULL
        cdef const void *key_addr = NULL
        cdef size_t key_len = 0
        cdef void *buf_addr = NULL
        cdef size_t buf_len = 0

        if txn:
            txn_addr = txn._c_hse_kvdb_txn
        if key is not None:
            key_addr = &key[0]
            key_len = key.shape[0]
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
            raise KvdbException(err)
        if not found:
            return None, 0

        if buf is None:
            return None, value_len

        if value_len < len(buf):
            return bytes(buf)[:value_len], value_len

        return bytes(buf), value_len

    def delete(self, const unsigned char [:]key, Transaction txn=None) -> None:
        """
        @SUB@ hse.Kvs.delete.__doc__
        """
        cdef unsigned int cflags = 0
        cdef hse_kvdb_txn *txn_addr = NULL
        cdef const void *key_addr = NULL
        cdef size_t key_len = 0

        if txn:
            txn_addr = txn._c_hse_kvdb_txn
        if key is not None:
            key_addr = &key[0]
            key_len = key.shape[0]

        cdef hse_err_t err = 0
        with nogil:
            err = hse_kvs_delete(self._c_hse_kvs, cflags, txn_addr, key_addr, key_len)
        if err != 0:
            raise KvdbException(err)

    def prefix_delete(self, const unsigned char [:]filt, txn: Transaction=None) -> int:
        """
        @SUB@ hse.Kvs.prefix_delete.__doc__
        """
        cdef unsigned int cflags = 0
        cdef hse_kvdb_txn *txn_addr = NULL
        cdef const void *filt_addr = NULL
        cdef size_t filt_len = 0

        if txn:
            txn_addr = txn._c_hse_kvdb_txn
        if filt is not None:
            filt_addr = &filt[0]
            filt_len = filt.shape[0]

        cdef hse_err_t err = 0
        cdef size_t kvs_pfx_len = 0
        with nogil:
            err = hse_kvs_prefix_delete(self._c_hse_kvs, cflags, txn_addr, filt_addr,
                filt_len, &kvs_pfx_len)
        if err != 0:
            raise KvdbException(err)

        return kvs_pfx_len

    def cursor(
        self,
        const unsigned char [:]filt=None,
        Transaction txn=None,
        flags: CursorFlag=0,
    ) -> Cursor:
        """
        @SUB@ hse.Kvs.cursor.__doc__
        """
        cursor: Cursor = Cursor(
            self,
            filt,
            txn=txn,
            flags=flags,
        )

        return cursor


class TransactionState(Enum):
    """
    @SUB@ hse.TransactionState.__doc__
    """
    INVALID = HSE_KVDB_TXN_INVALID
    ACTIVE = HSE_KVDB_TXN_ACTIVE
    COMMITTED = HSE_KVDB_TXN_COMMITTED
    ABORTED = HSE_KVDB_TXN_ABORTED


@cython.no_gc_clear
cdef class Transaction:
    """
    @SUB@ hse.Transaction.__doc__
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

        if self.state == TransactionState.ACTIVE:
            self.commit()

        with nogil:
            hse_kvdb_txn_free(self.kvdb._c_hse_kvdb, self._c_hse_kvdb_txn)
            self._c_hse_kvdb_txn = NULL

    def begin(self) -> None:
        """
        @SUB@ hse.Transaction.begin.__doc__
        """
        cdef hse_err_t err = 0
        with nogil:
            err = hse_kvdb_txn_begin(self.kvdb._c_hse_kvdb, self._c_hse_kvdb_txn)
        if err != 0:
            raise KvdbException(err)

    def commit(self) -> None:
        """
        @SUB@ hse.Transaction.commit.__doc__
        """
        cdef hse_err_t err = 0
        with nogil:
            err = hse_kvdb_txn_commit(self.kvdb._c_hse_kvdb, self._c_hse_kvdb_txn)
        if err != 0:
            raise KvdbException(err)

    def abort(self) -> None:
        """
        @SUB@ hse.Transaction.abort.__doc__
        """
        cdef hse_err_t err = 0
        with nogil:
            err = hse_kvdb_txn_abort(self.kvdb._c_hse_kvdb, self._c_hse_kvdb_txn)
        if err != 0:
            raise KvdbException(err)

    @property
    def state(self) -> TransactionState:
        """
        @SUB@ hse.Transaction.state.__doc__
        """
        cdef hse_kvdb_txn_state = HSE_KVDB_TXN_INVALID
        with nogil:
            state = hse_kvdb_txn_get_state(self.kvdb._c_hse_kvdb, self._c_hse_kvdb_txn)
        return TransactionState(state)


cdef class Cursor:
    def __cinit__(
        self,
        Kvs kvs,
        const unsigned char [:]filt=None,
        Transaction txn=None,
        flags: CursorFlag=0,
    ):
        self._eof = False

        cdef unsigned int cflags = int(flags)
        cdef hse_kvdb_txn *txn_addr = NULL
        cdef const void *filt_addr = NULL
        cdef size_t filt_len = 0

        if txn:
            txn_addr = txn._c_hse_kvdb_txn
        if filt is not None:
            filt_addr = &filt[0]
            filt_len = filt.shape[0]

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
            raise KvdbException(err)

    def __dealloc__(self):
        self.destroy()

    def __enter__(self):
        return self

    def __exit__(self, exc_type: Optional[Type[BaseException]], exc_val: Optional[BaseException], exc_tb: Optional[TracebackType]):
        self.destroy()

    def destroy(self):
        """
        @SUB@ hse.Cursor.destroy.__doc__
        """
        if self._c_hse_kvs_cursor:
            with nogil:
                hse_kvs_cursor_destroy(self._c_hse_kvs_cursor)
            self._c_hse_kvs_cursor = NULL

    def items(self) -> Iterator[Tuple[bytes, Optional[bytes]]]:
        """
        @SUB@ hse.Cursor.items.__doc__
        """
        def _iter():
            while True:
                key, val = self.read()
                if not self._eof:
                    yield key, val
                else:
                    return

        return _iter()

    def update(
        self,
        Transaction txn=None,
        flags: CursorFlag=0,
    ) -> None:
        """
        @SUB@ hse.Cursor.update.__doc__
        """
        cdef unsigned int cflags = int(flags)
        cdef hse_kvdb_txn *txn_addr = NULL

        if txn:
            txn_addr = txn._c_hse_kvdb_txn

        cdef hse_err_t err = 0
        with nogil:
            err = hse_kvs_cursor_update(self._c_hse_kvs_cursor, cflags, txn_addr)
        if err != 0:
            raise KvdbException(err)

    def seek(self, const unsigned char [:]key) -> Optional[bytes]:
        """
        @SUB@ hse.Cursor.seek.__doc__
        """
        cdef unsigned int cflags = 0
        cdef const void *key_addr = NULL
        cdef size_t key_len = 0
        if key is not None:
            key_addr = &key[0]
            key_len = key.shape[0]

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
            raise KvdbException(err)

        if not found:
            return None

        return (<char *>found)[:found_len]

    def seek_range(self, const unsigned char [:]filt_min, const unsigned char [:]filt_max) -> Optional[bytes]:
        """
        @SUB@ hse.Cursor.seek_range.__doc__
        """
        cdef unsigned int cflags = 0
        cdef const void *filt_min_addr = NULL
        cdef size_t filt_min_len = 0
        cdef const void *filt_max_addr = NULL
        cdef size_t filt_max_len = 0
        if filt_min is not None:
            filt_min_addr = &filt_min[0]
            filt_min_len = filt_min.shape[0]
        if filt_max is not None:
            filt_max_addr = &filt_max[0]
            filt_max_len = filt_max.shape[0]

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
            raise KvdbException(err)

        if not found:
            return None

        return (<char *>found)[:found_len]

    def read(self) -> Tuple[Optional[bytes], Optional[bytes]]:
        """
        @SUB@ hse.Cursor.read.__doc__
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
            raise KvdbException(err)

        self._eof = eof
        if eof:
            return None, None
        else:
            return (<char *>key)[:key_len], (<char *>value)[:value_len] if value else None

    @property
    def eof(self) -> bool:
        return self._eof


cdef class KvdbCompactStatus:
    """
    @SUB@ hse.KvdbCompactStatus.__doc__
    """
    @property
    def samp_lwm(self) -> int:
        """
        @SUB@ hse.KvdbCompactStatus.samp_lwm.__doc__
        """
        return self._c_hse_kvdb_compact_status.kvcs_samp_lwm

    @property
    def samp_hwm(self) -> int:
        """
        @SUB@ hse.KvdbCompactStatus.samp_hwm.__doc__
        """
        return self._c_hse_kvdb_compact_status.kvcs_samp_hwm

    @property
    def samp_curr(self) -> int:
        """
        @SUB@ hse.KvdbCompactStatus.samp_curr.__doc__
        """
        return self._c_hse_kvdb_compact_status.kvcs_samp_curr

    @property
    def active(self) -> int:
        """
        @SUB@ hse.KvdbCompactStatus.active.__doc__
        """
        return self._c_hse_kvdb_compact_status.kvcs_active

    @property
    def canceled(self) -> int:
        """
        @SUB@ hse.KvdbCompactStatus.canceled.__doc__
        """
        return self._c_hse_kvdb_compact_status.kvcs_canceled


cdef class KvdbStorageInfo:
    """
    @SUB@ hse.KvdbStorageInfo.__doc__
    """
    @property
    def total_bytes(self) -> int:
        """
        @SUB@ hse.KvdbStorageInfo.total_bytes.__doc__
        """
        return self._c_hse_kvdb_storage_info.total_bytes

    @property
    def available_bytes(self) -> int:
        """
        @SUB@ hse.KvdbStorageInfo.available_bytes.__doc__
        """
        return self._c_hse_kvdb_storage_info.available_bytes

    @property
    def allocated_bytes(self) -> int:
        """
        @SUB@ hse.KvdbStorageInfo.allocated_bytes.__doc__
        """
        return self._c_hse_kvdb_storage_info.allocated_bytes

    @property
    def used_bytes(self) -> int:
        """
        @SUB@ hse.KvdbStorageInfo.used_bytes.__doc__
        """
        return self._c_hse_kvdb_storage_info.used_bytes
