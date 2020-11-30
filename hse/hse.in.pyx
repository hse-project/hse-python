# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2020 Micron Technology, Inc. All rights reserved.

"""
KVDB_VERSION_STRING:

@SUB@ hse.KVDB_VERSION_STRING.__doc__

KVDB_VERSION_TAG:

@SUB@ hse.KVDB_VERSION_TAG.__doc__

KVDB_VERSION_SHA:

@SUB@ hse.KVDB_VERSION_SHA.__doc__
"""


import errno
import os
cimport cython
cimport hse_limits
from enum import Enum
from types import TracebackType
from typing import List, Optional, Tuple, Dict, Any, Iterator, Type, Union, Iterable
from libc.stdlib cimport free


# Throughout these bindings, you will see C pointers be set to NULL after their
# destruction. Please continue to follow this pattern as the HSE C code does
# not do this. We use NULL checks to protect against double free
# issues within the python bindings.


KVDB_VERSION_STRING = hse_kvdb_version_string().decode()
KVDB_VERSION_TAG = hse_kvdb_version_tag().decode()
KVDB_VERSION_SHA = hse_kvdb_version_sha().decode()


class KvdbException(Exception):
    """
    @SUB@ hse.KvdbException.__doc__
    """
    def __init__(self, hse_err_t returncode):
        self.returncode = hse_err_to_errno(returncode)
        self.message = os.strerror(self.returncode)

    def __str__(self):
        return self.message


cdef class Kvdb:
    def __cinit__(self, str mp_name, Params params=None):
        self._c_hse_kvdb = NULL

        cdef hse_params *p = params._c_hse_params if params else NULL

        err = hse_kvdb_open(mp_name.encode(), p, &self._c_hse_kvdb)
        if err != 0:
            raise KvdbException(err)

    def __dealloc__(self):
        pass

    def close(self) -> None:
        """
        @SUB@ hse.Kvdb.close.__doc__
        """
        if not self._c_hse_kvdb:
            return

        cdef hse_err_t err = hse_kvdb_close(self._c_hse_kvdb)
        if err != 0:
            raise KvdbException(err)

    @staticmethod
    def init() -> None:
        """
        @SUB@ hse.Kvdb.init.__doc__
        """
        cdef hse_err_t err = hse_kvdb_init()
        if err != 0:
            raise KvdbException(err)

    @staticmethod
    def fini() -> None:
        """
        @SUB@ hse.Kvdb.fini.__doc__
        """
        hse_kvdb_fini()

    @staticmethod
    def make(str mp_name, Params params=None) -> None:
        """
        @SUB@ hse.Kvdb.make.__doc__
        """
        mp_name_bytes = mp_name.encode()
        cdef hse_params *p = params._c_hse_params if params else NULL

        cdef hse_err_t err = hse_kvdb_make(<char *>mp_name_bytes, p)
        if err != 0:
            raise KvdbException(err)

    @staticmethod
    def open(str mp_name, Params params=None) -> Kvdb:
        """
        @SUB@ hse.Kvdb.open.__doc__
        """
        return Kvdb(mp_name, params=params)

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

    def kvs_make(self, str kvs_name, Params params=None) -> None:
        """
        @SUB@ hse.Kvdb.kvs_make.__doc__
        """
        kvs_name_bytes = kvs_name.encode()
        cdef hse_params *p = params._c_hse_params if params else NULL

        cdef hse_err_t err = hse_kvdb_kvs_make(self._c_hse_kvdb, <char *>kvs_name_bytes, p)
        if err != 0:
            raise KvdbException(err)

    def kvs_drop(self, str kvs_name) -> None:
        """
        @SUB@ hse.Kvdb.kvs_drop.__doc__
        """
        cdef hse_err_t err = hse_kvdb_kvs_drop(self._c_hse_kvdb, kvs_name.encode())
        if err != 0:
            raise KvdbException(err)

    def kvs_open(self, str kvs_name, Params params=None) -> Kvs:
        """
        @SUB@ hse.Kvdb.kvs_open.__doc__
        """
        return Kvs(self, kvs_name, params=params)

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

    def transaction(self) -> Transaction:
        """
        @SUB@ hse.Kvdb.transaction.__doc__
        """
        txn = Transaction(self)

        return txn


cdef class Kvs:
    def __cinit__(self, Kvdb kvdb, str kvs_name, Params params=None):
        self._c_hse_kvs = NULL

        cdef hse_params *p = params._c_hse_params if params else NULL

        cdef hse_err_t err = hse_kvdb_kvs_open(kvdb._c_hse_kvdb, kvs_name.encode(), p, &self._c_hse_kvs)
        if err != 0:
            raise KvdbException(err)

    def __dealloc__(self):
        pass

    def close(self) -> None:
        """
        @SUB@ hse.Kvs.close.__doc__
        """
        if not self._c_hse_kvs:
            return

        cdef hse_err_t err = hse_kvdb_kvs_close(self._c_hse_kvs)
        if err != 0:
            raise KvdbException(err)

    def put(self, const unsigned char [:]key, const unsigned char [:]value, priority: bool=False, Transaction txn=None) -> None:
        """
        @SUB@ hse.Kvs.put.__doc__
        """
        cdef hse_kvdb_opspec *opspec = HSE_KVDB_OPSPEC_INIT() if priority or txn else NULL
        if priority:
            opspec.kop_flags |= HSE_KVDB_KOP_FLAG_PRIORITY
        if txn:
            opspec.kop_txn = txn._c_hse_kvdb_txn

        cdef const void *key_addr = NULL
        cdef size_t key_len = 0
        cdef const void *value_addr = NULL
        cdef size_t value_len = 0
        if key is not None and len(key) > 0:
            key_addr = &key[0]
            key_len = len(key)
        if value is not None and len(value) > 0:
            value_addr = &value[0]
            value_len = len(value)

        cdef hse_err_t err = 0
        try:
            with nogil:
                err = hse_kvs_put(self._c_hse_kvs, opspec, key_addr, key_len, value_addr, value_len)
            if err != 0:
                raise KvdbException(err)
        finally:
            if opspec:
                free(opspec)

    def get(self, const unsigned char [:]key, Transaction txn=None, unsigned char [:]buf=bytearray(hse_limits.HSE_KVS_VLEN_MAX)) -> Optional[bytes]:
        """
        @SUB@ hse.Kvs.get.__doc__
        """
        value, _ = self.get_with_length(key, txn=txn, buf=buf)
        return value


    def get_with_length(self, const unsigned char [:]key, Transaction txn=None, unsigned char [:]buf=bytearray(hse_limits.HSE_KVS_VLEN_MAX)) -> Tuple[Optional[bytes], int]:
        """
        @SUB@ hse.Kvs.get_with_length.__doc__
        """
        cdef hse_kvdb_opspec *opspec = HSE_KVDB_OPSPEC_INIT() if txn else NULL
        if txn:
            opspec.kop_txn = txn._c_hse_kvdb_txn

        cdef const void *key_addr = NULL
        cdef size_t key_len = 0
        cdef void *buf_addr = NULL
        cdef size_t buf_len = 0
        if key is not None and len(key) > 0:
            key_addr = &key[0]
            key_len = len(key)
        if buf is not None and len(buf) > 0:
            buf_addr = &buf[0]
            buf_len = len(buf)

        cdef cbool found = False
        cdef size_t value_len = 0
        cdef hse_err_t err = 0
        try:
            with nogil:
                err = hse_kvs_get(self._c_hse_kvs, opspec, key_addr, key_len, &found, buf_addr, buf_len, &value_len)
            if err != 0:
                raise KvdbException(err)
            if not found:
                return None, 0
        finally:
            if opspec:
                free(opspec)

        if buf is None:
            return None, value_len

        if value_len < len(buf):
            return bytes(buf)[:value_len], value_len

        return bytes(buf), value_len

    def delete(self, const unsigned char [:]key, priority: bool=False, Transaction txn=None) -> None:
        """
        @SUB@ hse.Kvs.delete.__doc__
        """
        cdef hse_kvdb_opspec *opspec = HSE_KVDB_OPSPEC_INIT() if priority or txn else NULL
        if priority:
            opspec.kop_flags |= HSE_KVDB_KOP_FLAG_PRIORITY
        if txn:
            opspec.kop_txn = txn._c_hse_kvdb_txn

        cdef const void *key_addr = NULL
        cdef size_t key_len = 0
        if key is not None and len(key) > 0:
            key_addr = &key[0]
            key_len = len(key)

        cdef hse_err_t err = 0
        try:
            with nogil:
                err = hse_kvs_delete(self._c_hse_kvs, opspec, key_addr, key_len)
            if err != 0:
                raise KvdbException(err)
        finally:
            free(opspec)

    def prefix_delete(self, const unsigned char [:]filt, priority: bool=False, txn: Transaction=None) -> int:
        """
        @SUB@ hse.Kvs.prefix_delete.__doc__
        """
        cdef hse_kvdb_opspec *opspec = HSE_KVDB_OPSPEC_INIT() if priority or txn else NULL
        if priority:
            opspec.kop_flags |= HSE_KVDB_KOP_FLAG_PRIORITY
        if txn:
            opspec.kop_txn = txn._c_hse_kvdb_txn

        cdef const void *filt_addr = NULL
        cdef size_t filt_len = 0
        if filt is not None and len(filt) > 0:
            filt_addr = &filt[0]
            filt_len = len(filt)

        cdef hse_err_t err = 0
        cdef size_t kvs_pfx_len = 0
        try:
            with nogil:
                err = hse_kvs_prefix_delete(self._c_hse_kvs, opspec, filt_addr, filt_len, &kvs_pfx_len)
            if err != 0:
                raise KvdbException(err)
        finally:
            if opspec:
                free(opspec)

        return kvs_pfx_len

    def cursor(
        self,
        const unsigned char [:]filt=None,
        reverse: bool=False,
        static_view: bool=False,
        bind_txn: bool=False,
        Transaction txn=None
    ) -> Cursor:
        """
        @SUB@ hse.Kvs.cursor.__doc__
        """
        cursor: Cursor = Cursor(
            self,
            filt,
            reverse=reverse,
            static_view=static_view,
            bind_txn=bind_txn,
            txn=txn)

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
        if not self._c_hse_kvdb:
            return
        if not self._c_hse_kvdb_txn:
            return

        hse_kvdb_txn_free(self.kvdb._c_hse_kvdb, self._c_hse_kvdb_txn)

    def __enter__(self):
        self.begin()
        return self

    def __exit__(self, exc_type: Optional[Type[Exception]], exc_val: Optional[Any], exc_tb: Optional[TracebackType]):
        # PEP-343: If exception occurred in with statement, abort transaction
        if exc_tb:
            self.abort()
            return

        if self.state == TransactionState.ACTIVE:
            self.commit()

        hse_kvdb_txn_free(self.kvdb._c_hse_kvdb, self._c_hse_kvdb_txn)

    def begin(self) -> None:
        """
        @SUB@ hse.Transaction.begin.__doc__
        """
        cdef hse_err_t err = hse_kvdb_txn_begin(self.kvdb._c_hse_kvdb, self._c_hse_kvdb_txn)
        if err != 0:
            raise KvdbException(err)

    def commit(self) -> None:
        """
        @SUB@ hse.Transaction.commit.__doc__
        """
        cdef hse_err_t err = hse_kvdb_txn_commit(self.kvdb._c_hse_kvdb, self._c_hse_kvdb_txn)
        if err != 0:
            raise KvdbException(err)

    def abort(self) -> None:
        """
        @SUB@ hse.Transaction.abort.__doc__
        """
        cdef hse_err_t err = hse_kvdb_txn_abort(self.kvdb._c_hse_kvdb, self._c_hse_kvdb_txn)
        if err != 0:
            raise KvdbException(err)

    @property
    def state(self) -> TransactionState:
        """
        @SUB@ hse.Transaction.state.__doc__
        """
        return TransactionState(hse_kvdb_txn_get_state(self.kvdb._c_hse_kvdb, self._c_hse_kvdb_txn))


@cython.no_gc_clear
cdef class Cursor:
    """
    See the concept and best practices sections on the HSE Wiki at
    https://github.com/hse-project/hse/wiki
    """
    def __cinit__(
        self,
        Kvs kvs,
        const unsigned char [:]filt=None,
        reverse: bool=False,
        static_view: bool=False,
        bind_txn: bool=False,
        Transaction txn=None):
        self.txn = txn

        cdef hse_kvdb_opspec *opspec = HSE_KVDB_OPSPEC_INIT() if reverse or static_view or bind_txn or txn else NULL

        if reverse:
            opspec.kop_flags |= HSE_KVDB_KOP_FLAG_REVERSE
        if static_view:
            opspec.kop_flags |= HSE_KVDB_KOP_FLAG_STATIC_VIEW
        if bind_txn:
            opspec.kop_flags |= HSE_KVDB_KOP_FLAG_BIND_TXN
        if txn:
            opspec.kop_txn = txn._c_hse_kvdb_txn

        cdef const void *filt_addr = NULL
        cdef size_t filt_len = 0
        if filt is not None and len(filt) > 0:
            filt_addr = &filt[0]
            filt_len = len(filt)

        cdef hse_err_t err = 0
        try:
            with nogil:
                err = hse_kvs_cursor_create(
                    kvs._c_hse_kvs,
                    opspec,
                    filt_addr,
                    filt_len,
                    &self._c_hse_kvs_cursor
                )
            if err != 0:
                raise KvdbException(err)
        finally:
            if opspec:
                free(opspec)

    def __dealloc__(self):
        if self._c_hse_kvs_cursor:
            hse_kvs_cursor_destroy(self._c_hse_kvs_cursor)

    def __enter__(self):
        return self

    def __exit__(self, exc_type: Optional[Type[Exception]], exc_val: Optional[Any], exc_tb: Optional[TracebackType]):
        self.destroy()

    def destroy(self):
        """
        @SUB@ hse.Cursor.destroy.__doc__
        """
        if self._c_hse_kvs_cursor:
            hse_kvs_cursor_destroy(self._c_hse_kvs_cursor)
            self._c_hse_kvs_cursor = NULL

    def items(self, max_count: Optional[int]=None) -> Iterator[Tuple[bytes, Optional[bytes]]]:
        """
        @SUB@ hse.Cursor.items.__doc__
        """
        def _iter():
            count = 0

            while True:
                if max_count and count > max_count:
                    return

                count += 1
                key, val, eof = self.read()
                if not eof:
                    yield key, val
                else:
                    return

        return _iter()

    def update(self, static_view: Optional[bool]=None, bind_txn: Optional[bool]=None, txn: Transaction=None) -> None:
        """
        @SUB@ hse.Cursor.update.__doc__
        """
        cdef hse_kvdb_opspec *opspec = HSE_KVDB_OPSPEC_INIT() if static_view is not None or bind_txn is not None or txn is not self.txn else NULL

        if static_view:
            opspec.kop_flags |= HSE_KVDB_KOP_FLAG_STATIC_VIEW
        if bind_txn:
            opspec.kop_flags |= HSE_KVDB_KOP_FLAG_BIND_TXN
        if txn is not self.txn:
            opspec.kop_txn = txn._c_hse_kvdb_txn

        cdef hse_err_t err = 0
        try:
            with nogil:
                err = hse_kvs_cursor_update(self._c_hse_kvs_cursor, opspec)
            if err != 0:
                raise KvdbException(err)
        finally:
            if opspec:
                free(opspec)

    def seek(self, const unsigned char [:]key) -> Optional[bytes]:
        """
        @SUB@ hse.Cursor.seek.__doc__
        """
        cdef const void *key_addr = NULL
        cdef size_t key_len = 0
        if key is not None and len(key) > 0:
            key_addr = &key[0]
            key_len = len(key)

        cdef const void *found = NULL
        cdef size_t found_len = 0
        cdef hse_err_t err = 0
        with nogil:
            err = hse_kvs_cursor_seek(
                self._c_hse_kvs_cursor,
                NULL,
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
        cdef const void *filt_min_addr = NULL
        cdef size_t filt_min_len = 0
        cdef const void *filt_max_addr = NULL
        cdef size_t filt_max_len = 0
        if filt_min is not None and len(filt_min) > 0:
            filt_min_addr = &filt_min[0]
            filt_min_len = len(filt_min)
        if filt_max is not None and len(filt_max) > 0:
            filt_max_addr = &filt_max[0]
            filt_max_len = len(filt_max)

        cdef const void *found = NULL
        cdef size_t found_len = 0
        cdef hse_err_t err = 0
        with nogil:
            err = hse_kvs_cursor_seek_range(
                self._c_hse_kvs_cursor,
                NULL,
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

    def read(self) -> Tuple[Optional[bytes], Optional[bytes], bool]:
        """
        @SUB@ hse.Cursor.read.__doc__
        """
        cdef const void *key = NULL
        cdef const void *value = NULL
        cdef size_t key_len = 0
        cdef size_t value_len = 0
        cdef cbool eof = False
        cdef hse_err_t err = 0
        with nogil:
            err = hse_kvs_cursor_read(
                self._c_hse_kvs_cursor,
                NULL,
                &key,
                &key_len,
                &value,
                &value_len,
                &eof
            )
        if err != 0:
            raise KvdbException(err)

        if eof:
            return None, None, True
        else:
            return (<char*>key)[:key_len], (<char*>value)[:value_len] if value else None, False


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


Config = Dict[
    str,
    Optional[
        Union[
            str,
            int,
            float,
            bool,
            Iterable[Optional[Union[str, float, int, bool, "Config"]]],
            "Config",
        ]
    ],
]


cdef class Params:
    """
    @SUB@ hse.Params.__doc__
    """
    def __cinit__(self):
        cdef hse_err_t err = hse_params_create(&self._c_hse_params)
        if err != 0:
            raise KvdbException(err)

    def __dealloc__(self):
        if self._c_hse_params:
            hse_params_destroy(self._c_hse_params)

    def set(self, str key, str value) -> Params:
        """
        @SUB@ hse.Params.set.__doc__
        """
        cdef char *value_addr = NULL
        if value:
            value_bytes = value.encode()
            value_addr = value_bytes

        cdef hse_err_t err = hse_params_set(self._c_hse_params, key.encode(), value_addr)
        if err != 0:
            raise KvdbException(err)

        return self

    # 256 comes from hse_params.c HP_DICT_LET_MAX
    def get(self, str key, char [:]buf=bytearray(256)) -> Optional[str]:
        """
        @SUB@ hse.Params.get.__doc__
        """
        cdef char *buf_addr = NULL
        cdef size_t buf_len = 0
        if buf is not None and len(buf) > 0:
            buf_addr = &buf[0]
            buf_len = len(buf)

        cdef size_t param_len = 0
        cdef char *param = hse_params_get(self._c_hse_params, key.encode(), buf_addr, buf_len, &param_len)

        if buf is None:
            return None

        if len(buf) < param_len:
            return param[:param_len].decode() if param else None

        return param[:param_len].decode() if param else None

    def from_file(self, str path) -> Params:
        """
        @SUB@ hse.Params.from_file.__doc__
        """
        cdef hse_err_t err = hse_params_from_file(self._c_hse_params, path.encode())
        if err != 0:
            raise KvdbException(err)

        return self

    def from_string(self, str input) -> Params:
        """
        @SUB@ hse.Params.from_string.__doc__
        """
        cdef hse_err_t err = hse_params_from_string(self._c_hse_params, input.encode())
        if err != 0:
            raise KvdbException(err)

        return self
