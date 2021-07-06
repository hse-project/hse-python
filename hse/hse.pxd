# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2020-2021 Micron Technology, Inc. All rights reserved.

from libc.stdint cimport uint64_t
# Avoid interfering with Python bool type since Cython seems to struggle
# differentiating the two
from libcpp cimport bool as cbool


cdef extern from "Python.h":
    char* PyUnicode_AsUTF8(object unicode)


cdef extern from "hse/flags.h":
    cdef unsigned int HSE_FLAG_PUT_PRIORITY
    cdef unsigned int HSE_FLAG_PUT_VALUE_COMPRESSION_ON
    cdef unsigned int HSE_FLAG_PUT_VALUE_COMPRESSION_OFF

    cdef unsigned int HSE_FLAG_CURSOR_REVERSE
    cdef unsigned int HSE_FLAG_CURSOR_BIND_TXN
    cdef unsigned int HSE_FLAG_CURSOR_STATIC_VIEW


cdef extern from "hse/types.h":
    ctypedef uint64_t hse_err_t
    cdef struct hse_kvdb:
        pass
    cdef struct hse_kvs:
        pass
    cdef struct hse_kvs_cursor:
        pass
    cdef struct hse_kvdb_txn:
        pass

    cdef enum hse_kvdb_txn_state:
        HSE_KVDB_TXN_INVALID,
        HSE_KVDB_TXN_ACTIVE,
        HSE_KVDB_TXN_COMMITTED,
        HSE_KVDB_TXN_ABORTED

    cdef struct hse_kvdb_compact_status:
        unsigned int kvcs_samp_lwm
        unsigned int kvcs_samp_hwm
        unsigned int kvcs_samp_curr
        unsigned int kvcs_active
        unsigned int kvcs_canceled

    cdef struct hse_kvdb_storage_info:
        uint64_t total_bytes
        uint64_t available_bytes
        uint64_t allocated_bytes
        uint64_t used_bytes
        char capacity_path[4096]
        char staging_path[4096]

    cdef enum hse_kvs_pfx_probe_cnt:
        HSE_KVS_PFX_FOUND_ZERO,
        HSE_KVS_PFX_FOUND_ONE,
        HSE_KVS_PFX_FOUND_MUL


cdef extern from "hse/hse.h":
    cdef int hse_err_to_errno(hse_err_t err)
    cdef size_t hse_strerror(hse_err_t err, char *buf, size_t buf_len)

    hse_err_t hse_init(size_t paramc, const char *const *paramv)
    void hse_fini()

    hse_err_t hse_kvdb_create(const char *kvdb_home, size_t paramc, char **paramv)
    hse_err_t hse_kvdb_drop(const char *kvdb_home, size_t paramc, char **paramv)
    hse_err_t hse_kvdb_open(const char *kvdb_home, size_t paramc, char **paramv, hse_kvdb **kvdb)
    hse_err_t hse_kvdb_close(hse_kvdb *kvdb)
    hse_err_t hse_kvdb_kvs_names_get(hse_kvdb *kvdb, size_t *namec, char ***namev) nogil
    void hse_kvdb_kvs_names_free(hse_kvdb *kvdb, char **namev) nogil
    hse_err_t hse_kvdb_kvs_create(hse_kvdb *kvdb, const char *kvs_name, size_t paramc, char **paramv)
    hse_err_t hse_kvdb_kvs_drop(hse_kvdb *kvdb, const char *kvs_name)
    hse_err_t hse_kvdb_kvs_open(
        hse_kvdb * kvdb,
        const char *kvs_name,
        size_t paramc,
        char **paramv,
        hse_kvs **kvs_out)
    hse_err_t hse_kvdb_kvs_close(hse_kvs *kvs)

    hse_err_t hse_kvs_put(
        hse_kvs *kvs,
        unsigned int flags,
        hse_kvdb_txn *txn,
        const void *key,
        size_t key_len,
        const void *val,
        size_t val_len) nogil
    hse_err_t hse_kvs_get(
        hse_kvs *kvs,
        unsigned int flags,
        hse_kvdb_txn *txn,
        const void *key,
        size_t key_len,
        cbool *found,
        void *buf,
        size_t buf_len,
        size_t *val_len) nogil
    hse_err_t hse_kvs_delete(
        hse_kvs *kvs,
        unsigned int flags,
        hse_kvdb_txn *txn,
        const void *key,
        size_t key_len) nogil
    hse_err_t hse_kvs_prefix_delete(
        hse_kvs *kvs,
        unsigned int flags,
        hse_kvdb_txn *txn,
        const void *filt,
        size_t filt_len,
        size_t *kvs_pfx_len) nogil
    hse_err_t hse_kvs_prefix_probe(
        hse_kvs *kvs,
        unsigned int flags,
        hse_kvdb_txn *txn,
        const void *pfx,
        size_t pfx_len,
        hse_kvs_pfx_probe_cnt *found,
        void *keybuf,
        size_t keybuf_sz,
        size_t *key_len,
        void *valbuf,
        size_t valbuf_sz,
        size_t *val_len) nogil

    cdef unsigned int HSE_FLAG_SYNC_ASYNC

    hse_err_t hse_kvdb_sync(hse_kvdb *kvdb, unsigned int flags) nogil

    cdef int HSE_FLAG_KVDB_COMPACT_CANCEL
    cdef int HSE_FLAG_KVDB_COMPACT_SAMP_LWM

    hse_err_t hse_kvdb_compact(hse_kvdb *kvdb, int flags) nogil

    hse_err_t hse_kvdb_compact_status_get(hse_kvdb *kvdb, hse_kvdb_compact_status *status) nogil

    hse_err_t hse_kvdb_storage_info_get(hse_kvdb *kvdb, hse_kvdb_storage_info *info) nogil

    hse_kvdb_txn *hse_kvdb_txn_alloc(hse_kvdb *kvdb) nogil
    void hse_kvdb_txn_free(hse_kvdb *kvdb, hse_kvdb_txn *txn) nogil
    hse_err_t hse_kvdb_txn_begin(hse_kvdb *kvdb, hse_kvdb_txn *txn) nogil
    hse_err_t hse_kvdb_txn_commit(hse_kvdb *kvdb, hse_kvdb_txn *txn) nogil
    hse_err_t hse_kvdb_txn_abort(hse_kvdb *kvdb, hse_kvdb_txn *txn) nogil
    hse_kvdb_txn_state hse_kvdb_txn_get_state(hse_kvdb *kvdb, hse_kvdb_txn *txn) nogil

    hse_err_t hse_kvs_cursor_create(
        hse_kvs *kvs,
        unsigned int flags,
        hse_kvdb_txn *txn,
        const void *filt,
        size_t filt_len,
        hse_kvs_cursor **cursor) nogil
    hse_err_t hse_kvs_cursor_update(
        hse_kvs_cursor *cursor,
        unsigned int flags,
        hse_kvdb_txn *txn) nogil
    hse_err_t hse_kvs_cursor_seek(
        hse_kvs_cursor *cursor,
        unsigned int flags,
        const void *key,
        size_t key_len,
        const void **found,
        size_t *found_len) nogil
    hse_err_t hse_kvs_cursor_seek_range(
        hse_kvs_cursor *cursor,
        unsigned int flags,
        const void *filt_min,
        size_t filt_min_len,
        const void *filt_max,
        size_t filt_max_len,
        const void **found,
        size_t *found_len) nogil
    hse_err_t hse_kvs_cursor_read(
        hse_kvs_cursor  *cursor,
        unsigned int flags,
        const void **key,
        size_t *key_len,
        const void **val,
        size_t *val_len,
        cbool *eof) nogil
    hse_err_t hse_kvs_cursor_destroy(hse_kvs_cursor *cursor) nogil


cdef class Kvdb:
    cdef hse_kvdb *_c_hse_kvdb


cdef class Kvs:
    cdef hse_kvs *_c_hse_kvs


cdef class Transaction:
    cdef hse_kvdb_txn *_c_hse_kvdb_txn
    cdef Kvdb kvdb


cdef class Cursor:
    cdef hse_kvs_cursor *_c_hse_kvs_cursor
    cdef cbool _eof


cdef class KvdbCompactStatus:
    cdef hse_kvdb_compact_status _c_hse_kvdb_compact_status

cdef class KvdbStorageInfo:
    cdef hse_kvdb_storage_info _c_hse_kvdb_storage_info
