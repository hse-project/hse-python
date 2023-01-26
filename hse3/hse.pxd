# SPDX-License-Identifier: Apache-2.0 OR MIT
#
# SPDX-FileCopyrightText: Copyright 2020 Micron Technology, Inc.

from libc.stdint cimport uint64_t

# Avoid interfering with Python bool type since Cython seems to struggle
# differentiating the two
from libcpp cimport bool as cbool


cdef extern from "Python.h":
    char* PyUnicode_AsUTF8(object unicode)


cdef extern from "hse/flags.h":
    cdef unsigned int HSE_KVS_PUT_PRIO
    cdef unsigned int HSE_KVS_PUT_VCOMP_OFF
    cdef unsigned int HSE_KVS_PUT_VCOMP_ON

    cdef unsigned int HSE_CURSOR_CREATE_REV

    IF HSE_PYTHON_EXPERIMENTAL == 1:
        cdef unsigned int HSE_KVDB_COMPACT_CANCEL
        cdef unsigned int HSE_KVDB_COMPACT_SAMP_LWM


cdef extern from "hse/types.h":
    ctypedef uint64_t hse_err_t

    cdef enum hse_err_ctx:
        HSE_ERR_CTX_NONE
        HSE_ERR_CTX_TXN_EXPIRED

    cdef struct hse_kvdb:
        pass

    cdef enum hse_mclass:
        HSE_MCLASS_CAPACITY
        HSE_MCLASS_STAGING
        HSE_MCLASS_PMEM

    cdef const char *HSE_MCLASS_CAPACITY_NAME
    cdef const char *HSE_MCLASS_STAGING_NAME
    cdef const char *HSE_MCLASS_PMEM_NAME

    cdef struct hse_mclass_info:
        uint64_t mi_allocated_bytes;
        uint64_t mi_used_bytes
        uint64_t mi_reserved[8]
        char mi_path[PATH_MAX]

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


IF HSE_PYTHON_EXPERIMENTAL == 1:
    cdef extern from "hse/experimental.h":
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
        cdef struct hse_kvdb_compact_status:
            unsigned int kvcs_samp_lwm
            unsigned int kvcs_samp_hwm
            unsigned int kvcs_samp_curr
            unsigned int kvcs_active
            unsigned int kvcs_canceled
        cdef enum hse_kvs_pfx_probe_cnt:
            HSE_KVS_PFX_FOUND_ZERO,
            HSE_KVS_PFX_FOUND_ONE,
            HSE_KVS_PFX_FOUND_MUL
        hse_err_t hse_kvdb_compact(hse_kvdb *kvdb, int flags) nogil
        hse_err_t hse_kvdb_compact_status_get(hse_kvdb *kvdb, hse_kvdb_compact_status *status) nogil

cdef extern from "hse/hse.h":
    cdef int hse_err_to_errno(hse_err_t err)
    cdef hse_err_ctx hse_err_to_ctx(hse_err_t err)
    cdef size_t hse_strerror(hse_err_t err, char *buf, size_t buf_len)

    hse_err_t hse_init(const char *config, size_t paramc, const char *const *paramv)
    void hse_fini()
    hse_err_t hse_param_get(const char *param, char *buf, size_t buf_sz, size_t *needed_sz) nogil

    hse_err_t hse_kvdb_create(const char *kvdb_home, size_t paramc, const char *const *paramv)
    hse_err_t hse_kvdb_drop(const char *kvdb_home)
    hse_err_t hse_kvdb_open(const char *kvdb_home, size_t paramc, const char *const *, hse_kvdb **kvdb)
    hse_err_t hse_kvdb_close(hse_kvdb *kvdb)
    const char *hse_kvdb_home_get(hse_kvdb *kvdb) nogil
    hse_err_t hse_kvdb_param_get(
        hse_kvdb *kvdb,
        const char *param,
        char *buf,
        size_t buf_sz,
        size_t *needed_sz) nogil
    hse_err_t hse_kvdb_kvs_names_get(hse_kvdb *kvdb, size_t *namec, char ***namev) nogil
    void hse_kvdb_kvs_names_free(hse_kvdb *kvdb, char **namev) nogil
    hse_err_t hse_kvdb_mclass_info_get(hse_kvdb *kvdb, hse_mclass mclass, hse_mclass_info *info) nogil
    hse_err_t hse_kvdb_mclass_is_configured(hse_kvdb *kvdb, hse_mclass mclass) nogil
    hse_err_t hse_kvdb_kvs_create(hse_kvdb *kvdb, const char *kvs_name, size_t paramc, const char *const *)
    hse_err_t hse_kvdb_kvs_drop(hse_kvdb *kvdb, const char *kvs_name)
    hse_err_t hse_kvdb_kvs_open(
        hse_kvdb * kvdb,
        const char *kvs_name,
        size_t paramc,
        const char *const *,
        hse_kvs **kvs_out)
    hse_err_t hse_kvdb_kvs_close(hse_kvs *kvs)
    const char *hse_mclass_name_get(hse_mclass mclass) nogil

    const char *hse_kvs_name_get(hse_kvs *kvs) nogil
    hse_err_t hse_kvs_param_get(
        hse_kvs *kvs,
        const char *param,
        char *buf,
        size_t buf_sz,
        size_t *needed_sz) nogil
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
        const void *pfx,
        size_t pfx_len) nogil

    cdef unsigned int HSE_KVDB_SYNC_ASYNC

    hse_err_t hse_kvdb_sync(hse_kvdb *kvdb, unsigned int flags) nogil

    hse_err_t hse_kvdb_storage_add(const char *kvdb_home, size_t paramc, const char *const *paramv) nogil

    hse_kvdb_txn *hse_kvdb_txn_alloc(hse_kvdb *kvdb) nogil
    void hse_kvdb_txn_free(hse_kvdb *kvdb, hse_kvdb_txn *txn) nogil
    hse_err_t hse_kvdb_txn_begin(hse_kvdb *kvdb, hse_kvdb_txn *txn) nogil
    hse_err_t hse_kvdb_txn_commit(hse_kvdb *kvdb, hse_kvdb_txn *txn) nogil
    hse_err_t hse_kvdb_txn_abort(hse_kvdb *kvdb, hse_kvdb_txn *txn) nogil
    hse_kvdb_txn_state hse_kvdb_txn_state_get(hse_kvdb *kvdb, hse_kvdb_txn *txn) nogil

    hse_err_t hse_kvs_cursor_create(
        hse_kvs *kvs,
        unsigned int flags,
        hse_kvdb_txn *txn,
        const void *filt,
        size_t filt_len,
        hse_kvs_cursor **cursor) nogil
    hse_err_t hse_kvs_cursor_update_view(
        hse_kvs_cursor *cursor,
        unsigned int flags) nogil
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
    hse_err_t hse_kvs_cursor_read_copy(
        hse_kvs_cursor *cursor,
        unsigned int flags,
        void *keybuf,
        size_t keybuf_sz,
        size_t *key_len,
        void *valbuf,
        size_t valbuf_sz,
        size_t *val_len,
        cbool *eof) nogil
    hse_err_t hse_kvs_cursor_destroy(hse_kvs_cursor *cursor) nogil


cdef class Kvdb:
    cdef hse_kvdb *_c_hse_kvdb


cdef class Kvs:
    cdef hse_kvs *_c_hse_kvs


cdef class KvdbTransaction:
    cdef hse_kvdb_txn *_c_hse_kvdb_txn
    cdef Kvdb kvdb


cdef class KvsCursor:
    cdef hse_kvs_cursor *_c_hse_kvs_cursor
    cdef cbool _eof


cdef class MclassInfo:
    cdef hse_mclass_info _c_hse_mclass_info


IF HSE_PYTHON_EXPERIMENTAL == 1:
    cdef class KvdbCompactStatus:
        cdef hse_kvdb_compact_status _c_hse_kvdb_compact_status
