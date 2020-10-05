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
import yaml
cimport hse_limits
from ctypes import c_int
from enum import Enum
from types import TracebackType
from typing import List, Optional, Tuple, Dict, Any, Iterator, Type
from libc.stdlib cimport calloc, free


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


cdef hse_kvdb_opspec *HSE_KVDB_OPSPEC_INIT():
    cdef hse_kvdb_opspec *opspec = <hse_kvdb_opspec *>calloc(1, sizeof(hse_kvdb_opspec))
    if not opspec:
        raise MemoryError()

    opspec.kop_opaque = 0xb0de0001

    return opspec


cdef class Kvdb:
    cdef hse_kvdb *_c_hse_kvdb

    def __cinit__(self):
        self._c_hse_kvdb = NULL

    def __dealloc__(self):
        pass

    def close(self):
        """
        @SUB@ hse.Kvdb.close.__doc__
        """
        if not self._c_hse_kvdb:
            return

        cdef hse_err_t err = hse_kvdb_close(self._c_hse_kvdb)
        if err != 0:
            raise KvdbException(err)

    @staticmethod
    def init():
        """
        @SUB@ hse.Kvdb.init.__doc__
        """
        cdef hse_err_t err = hse_kvdb_init()
        if err != 0:
            raise KvdbException(err)

    @staticmethod
    def fini():
        """
        @SUB@ hse.Kvdb.fini.__doc__
        """
        hse_kvdb_fini()

    @staticmethod
    def make(mp_name: str, Params params=None):
        """
        @SUB@ hse.Kvdb.make.__doc__
        """
        cdef mp_name_bytes = mp_name.encode()
        cdef hse_params *p = params._c_hse_params if params else NULL

        cdef hse_err_t err = hse_kvdb_make(<char *>mp_name_bytes, p)
        if err != 0:
            raise KvdbException(err)

    @staticmethod
    def open(mp_name: str, Params params=None) -> Kvdb:
        """
        @SUB@ hse.Kvdb.open.__doc__
        """
        cdef mp_name_bytes = mp_name.encode()
        cdef hse_params *p = params._c_hse_params if params else NULL

        kvdb: Kvdb = Kvdb()

        err = hse_kvdb_open(<char *>mp_name_bytes, p, &kvdb._c_hse_kvdb)
        if err != 0:
            raise KvdbException(err)
        if not kvdb._c_hse_kvdb:
            raise MemoryError()

        return kvdb

    def get_names(self) -> List[str]:
        """
        @SUB@ hse.Kvdb.get_names.__doc__
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

    def kvs_make(self, kvs_name: str, Params params=None):
        """
        @SUB@ hse.Kvdb.kvs_make.__doc__
        """
        cdef kvs_name_bytes = kvs_name.encode()
        cdef hse_params *p = params._c_hse_params if params else NULL

        cdef hse_err_t err = hse_kvdb_kvs_make(self._c_hse_kvdb, <char *>kvs_name_bytes, p)
        if err != 0:
            raise KvdbException(err)

    def kvs_drop(self, kvs_name: str):
        """
        @SUB@ hse.Kvdb.kvs_drop.__doc__
        """
        cdef kvs_name_bytes = kvs_name.encode()
        cdef hse_err_t err = hse_kvdb_kvs_drop(self._c_hse_kvdb, <char *>kvs_name_bytes)
        if err != 0:
            raise KvdbException(err)

    def kvs_open(self, kvs_name: str, Params params=None) -> Kvs:
        """
        @SUB@ hse.Kvdb.kvs_open.__doc__
        """
        cdef hse_params *p = params._c_hse_params if params else NULL
        cdef kvs_name_bytes = kvs_name.encode()

        kvs: Kvs = Kvs()

        cdef hse_err_t err = hse_kvdb_kvs_open(self._c_hse_kvdb, <char *>kvs_name_bytes, p, &kvs._c_hse_kvs)
        if err != 0:
            raise KvdbException(err)
        if not kvs._c_hse_kvs:
            raise MemoryError()

        return kvs

    def sync(self):
        """
        @SUB@ hse.Kvdb.sync.__doc__
        """
        cdef hse_err_t err = hse_kvdb_sync(self._c_hse_kvdb)
        if err != 0:
            raise KvdbException(err)

    def flush(self):
        """
        @SUB@ hse.Kvdb.flush.__doc__
        """
        cdef hse_err_t err = hse_kvdb_flush(self._c_hse_kvdb)
        if err != 0:
            raise KvdbException(err)

    def compact(self, cancel=False, samp_lwm=False):
        """
        @SUB@ hse.Kvdb.compact.__doc__
        """
        cdef int flags = 0
        if cancel:
            flags |= HSE_KVDB_COMP_FLAG_CANCEL
        if samp_lwm:
            flags |= HSE_KVDB_COMP_FLAG_SAMP_LWM

        cdef hse_err_t err = hse_kvdb_compact(self._c_hse_kvdb, flags)
        if err != 0:
            raise KvdbException(err)

    @property
    def compact_status(self) -> KvdbCompactStatus:
        """
        @SUB@ hse.Kvdb.compact_status.__doc__
        """
        status: KvdbCompactStatus = KvdbCompactStatus()
        cdef hse_err_t err = hse_kvdb_compact_status_get(self._c_hse_kvdb, &status._c_hse_kvdb_compact_status)
        if err != 0:
            raise KvdbException(err)
        return status

    def txn_alloc(self) -> KvdbTxn:
        """
        @SUB@ hse.Kvdb.txn_alloc.__doc__
        """
        txn: KvdbTxn = KvdbTxn()

        txn._c_hse_kvdb = self._c_hse_kvdb
        txn._c_hse_kvdb_txn = hse_kvdb_txn_alloc(self._c_hse_kvdb)
        if not txn._c_hse_kvdb_txn:
            raise MemoryError()

        return txn


cdef class Kvs:
    cdef hse_kvs *_c_hse_kvs

    def __cinit__(self):
        self._c_hse_kvs = NULL

    def __dealloc__(self):
        pass

    def close(self):
        """
        @SUB@ hse.Kvs.close.__doc__
        """
        if not self._c_hse_kvs:
            return

        cdef hse_err_t err = hse_kvdb_kvs_close(self._c_hse_kvs)
        if err != 0:
            raise KvdbException(err)

    def put(self, const unsigned char [:]key, const unsigned char [:]value, priority=False, KvdbTxn txn=None):
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
        cdef value_len = 0
        if key is not None and len(key) > 0:
            key_addr = &key[0]
            key_len = len(key)
        if value is not None and len(value) > 0:
            value_addr = &value[0]
            value_len = len(value)

        cdef hse_err_t err = 0
        try:
            err = hse_kvs_put(self._c_hse_kvs, opspec, key_addr, key_len, value_addr, value_len)
            if err != 0:
                raise KvdbException(err)
        finally:
            if opspec:
                free(opspec)

    def get(self, const unsigned char [:]key, KvdbTxn txn=None, unsigned char [:]buf=bytearray(hse_limits.HSE_KVS_VLEN_MAX)) -> Optional[bytes]:
        """
        @SUB@ hse.Kvs.get.__doc__
        """
        value, length = self.get_with_length(key, txn=txn, buf=buf)
        return value[:length] if len(value) > length else value


    def get_with_length(self, const unsigned char [:]key, KvdbTxn txn=None, unsigned char [:]buf=bytearray(hse_limits.HSE_KVS_VLEN_MAX)) -> Tuple[Optional[bytes], int]:
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

        cdef bool found = False
        cdef size_t value_len = 0
        cdef hse_err_t err = 0
        try:
            err = hse_kvs_get(self._c_hse_kvs, opspec, key_addr, key_len, &found, buf_addr, buf_len, &value_len)
            if err != 0:
                raise KvdbException(err)
            if not found:
                return None
        finally:
            if opspec:
                free(opspec)

        return bytes(buf), value_len

    def delete(self, const unsigned char [:]key, priority=False, KvdbTxn txn=None):
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
            err = hse_kvs_delete(self._c_hse_kvs, opspec, key_addr, key_len)
            if err != 0:
                raise KvdbException(err)
        finally:
            free(opspec)

    def prefix_delete(self, const unsigned char [:]filt, priority=False, KvdbTxn txn=None):
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
        try:
            err = hse_kvs_prefix_delete(self._c_hse_kvs, opspec, filt_addr, filt_len, NULL)
            if err != 0:
                raise KvdbException(err)
        finally:
            if opspec:
                free(opspec)

    def cursor_create(
        self,
        const unsigned char [:]filt=None,
        reverse=False,
        static_view=False,
        bind_txn=False,
        KvdbTxn txn=None
    ):
        """
        @SUB@ hse.Kvs.cursor_create.__doc__
        """
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

        cursor: KvsCursor = KvsCursor()
        cursor._c_hse_kvdb_txn = txn._c_hse_kvdb_txn

        cdef hse_err_t err = 0
        try:
            err = hse_kvs_cursor_create(
                self._c_hse_kvs,
                opspec,
                filt_addr,
                filt_len,
                &cursor._c_hse_kvs_cursor
            )
            if err != 0:
                raise KvdbException(err)
        finally:
            if opspec:
                free(opspec)

        return cursor


class KvdbTxnState(Enum):
    """
    @SUB@ hse.KvdbTxnState.__doc__
    """
    INVALID = HSE_KVDB_TXN_INVALID
    ACTIVE = HSE_KVDB_TXN_ACTIVE
    COMMITTED = HSE_KVDB_TXN_COMMITTED
    ABORTED = HSE_KVDB_TXN_ABORTED


cdef class KvdbTxn:
    """
    @SUB@ hse.KvdbTxn.__doc__
    """
    cdef hse_kvdb_txn *_c_hse_kvdb_txn
    cdef hse_kvdb *_c_hse_kvdb

    def __cinit__(self):
        self._c_hse_kvdb_txn = NULL
        self._c_hse_kvdb = NULL

    def __dealloc__(self):
        if not self._c_hse_kvdb:
            return
        if not self._c_hse_kvdb_txn:
            return

        hse_kvdb_txn_free(self._c_hse_kvdb, self._c_hse_kvdb_txn)

    def __enter__(self):
        self.begin()
        return self

    def __exit__(self, exc_type: Optional[Type[Exception]], exc_val: Optional[Any], exc_tb: Optional[TracebackType]):
        # PEP-343: If exception occurred in with statement, abort transaction
        if exc_tb:
            self.abort()
            return

        self.commit()

    def begin(self):
        """
        @SUB@ hse.KvdbTxn.begin.__doc__
        """
        cdef hse_err_t err = hse_kvdb_txn_begin(self._c_hse_kvdb, self._c_hse_kvdb_txn)
        if err != 0:
            raise KvdbException(err)

    def commit(self):
        """
        @SUB@ hse.KvdbTxn.commit.__doc__
        """
        cdef hse_err_t err = hse_kvdb_txn_commit(self._c_hse_kvdb, self._c_hse_kvdb_txn)
        if err != 0:
            raise KvdbException(err)

    def abort(self):
        """
        @SUB@ hse.KvdbTxn.abort.__doc__
        """
        cdef hse_err_t err = hse_kvdb_txn_abort(self._c_hse_kvdb, self._c_hse_kvdb_txn)
        if err != 0:
            raise KvdbException(err)

    @property
    def state(self) -> KvdbTxnState:
        """
        @SUB@ hse.KvdbTxn.state.__doc__
        """
        return KvdbTxnState(hse_kvdb_txn_get_state(self._c_hse_kvdb, self._c_hse_kvdb_txn))


cdef class KvsCursor:
    """
    See the concept and best practices sections on the HSE Wiki at
    https://github.com/hse-project/hse/wiki
    """
    cdef hse_kvs_cursor *_c_hse_kvs_cursor
    cdef hse_kvdb_txn *_c_hse_kvdb_txn

    def __cinit__(self):
        self._c_hse_kvs_cursor = NULL
        self._c_hse_kvdb_txn = NULL

    def __dealloc__(self):
        if self._c_hse_kvs_cursor:
            hse_kvs_cursor_destroy(self._c_hse_kvs_cursor)

    def __enter__(self):
        return self

    def __exit__(self, exc_type: Optional[Type[Exception]], exc_val: Optional[Any], exc_tb: Optional[TracebackType]):
        self.destroy()

    def destroy(self):
        """
        @SUB@ hse.KvsCursor.destroy.__doc__
        """
        if self._c_hse_kvs_cursor:
            hse_kvs_cursor_destroy(self._c_hse_kvs_cursor)
            self._c_hse_kvs_cursor = NULL

    def items(self, max_count=None) -> Iterator[Tuple[bytes, Optional[bytes]]]:
        """
        @SUB@ hse.KvsCursor.items.__doc__
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
                    self.destroy()
                    return

        return _iter()

    def update(self, reverse=None, static_view=None, bind_txn=None, KvdbTxn txn=None):
        """
        @SUB@ hse.KvsCursor.update.__doc__
        """
        txn_changed = (self._c_hse_kvdb_txn is not NULL and not txn) or self._c_hse_kvdb_txn != txn._c_hse_kvdb_txn
        cdef hse_kvdb_opspec *opspec = HSE_KVDB_OPSPEC_INIT() if reverse is not None or static_view is not None or bind_txn is not None or txn_changed else NULL

        if reverse:
            opspec.kop_flags |= HSE_KVDB_KOP_FLAG_REVERSE
        if static_view:
            opspec.kop_flags |= HSE_KVDB_KOP_FLAG_STATIC_VIEW
        if bind_txn:
            opspec.kop_flags |= HSE_KVDB_KOP_FLAG_BIND_TXN
        if txn is not self.__txn:
            opspec.kop_txn = txn._c_hse_kvdb_txn

        cdef hse_err_t err = 0
        try:
            err = hse_kvs_cursor_update(self._c_hse_kvs_cursor, opspec)
            if err != 0:
                raise KvdbException(err)
        finally:
            if opspec:
                free(opspec)

    def seek(self, const unsigned char [:]key) -> Optional[bytes]:
        """
        @SUB@ hse.KvsCursor.seek.__doc__
        """
        cdef const void *key_addr = NULL
        cdef size_t key_len = 0
        if key is not None and len(key) > 0:
            key_addr = &key[0]
            key_len = len(key)

        cdef const void *found = NULL
        cdef size_t found_len = 0
        cdef hse_err_t err = hse_kvs_cursor_seek(
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

        return bytes((<char *>found)[:found_len])

    def seek_range(self, const unsigned char [:]filt_min, const unsigned char [:]filt_max) -> Optional[bytes]:
        """
        @SUB@ hse.KvsCursor.seek_range.__doc__
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
        cdef hse_err_t err = hse_kvs_cursor_seek_range(
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

    # Compiler error when using Tuple[bytes, Optional[bytes], bool]
    # When we move to Python >= 3.8, use
    # Tuple[bytes, bytes, Union[Literal[True], Literal[False]]] as a workaround
    # int is just a placeholder since return types in Cython seem to be
    # ignored
    def read(self) -> Tuple[bytes, Optional[bytes], bool]:
        """
        @SUB@ hse.KvsCursor.read.__doc__
        """
        cdef const void *key = NULL
        cdef const void *value = NULL
        cdef size_t key_len = 0
        cdef size_t value_len = 0
        cdef bool eof = False
        cdef hse_err_t err = hse_kvs_cursor_read(
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
    cdef hse_kvdb_compact_status _c_hse_kvdb_compact_status

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


cdef class Params:
    cdef hse_params *_c_hse_params

    def __cinit__(self):
        self._c_hse_params = NULL

    def __dealloc__(self):
        if self._c_hse_params:
            hse_params_destroy(self._c_hse_params)

    def __getitem__(self, key) -> Optional[str]:
        return self.get(key)

    def __setitem__(self, key, value):
        self.set(key, value)

    def set(self, key: str, value: str):
        """
        @SUB@ hse.Params.set.__doc__
        """
        hse_params_set(self._c_hse_params, key.encode(), value.encode())

    # 256 comes from hse_params.c HP_DICT_LET_MAX
    def get(self, key: str, char [:]buf=bytearray(256)) -> Optional[str]:
        """
        @SUB@ hse.Params.get.__doc__
        """
        cdef char *buf_addr = NULL
        cdef size_t buf_len = 0
        if buf is not None and len(buf) > 0:
            buf_addr = &buf[0]
            buf_len = len(buf)

        cdef size_t param_len = 0
        cdef char *param = hse_params_get(self._c_hse_params, key, buf_addr, buf_len, &param_len)
        return param[:param_len] if param else None

    @staticmethod
    def create() -> Params:
        """
        @SUB@ hse.Params.create.__doc__
        """
        p: Params = Params()

        cdef hse_err_t err = hse_params_create(&p._c_hse_params)
        if err == errno.ENOMEM:
            raise MemoryError()
        if err != 0:
            raise KvdbException(err)

        return p

    @staticmethod
    def from_dict(params: Dict[str, str]) -> Params:
        """
        @SUB@ hse.Params.from_dict.__doc__
        """
        p: Params = Params()

        input_bytes = yaml.dump(params).encode()
        cdef int err = hse_params_from_string(p._c_hse_params, <char *>input_bytes)
        if err == errno.ENOMEM:
            raise MemoryError()
        if err != 0:
            raise KvdbException(err)

        return p

    @staticmethod
    def from_file(path: str) -> Params:
        """
        @SUB@ hse.Params.from_file.__doc__
        """
        cdef path_bytes = path.encode()

        p: Params = Params()

        cdef int err = hse_params_from_file(p._c_hse_params, <char *>path_bytes)
        if err == errno.ENOMEM:
            raise MemoryError()
        if err != 0:
            raise KvdbException(err)

        return p

    @staticmethod
    def from_string(input: str) -> Params:
        """
        @SUB@ hse.Params.from_string.__doc__
        """
        cdef input_bytes = input.encode()

        p: Params = Params()

        cdef int err = hse_params_from_string(p._c_hse_params, <char *>input_bytes)
        if err == errno.ENOMEM:
            raise MemoryError()
        if err != 0:
            raise KvdbException(err)

        return p