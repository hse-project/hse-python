# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2020-2021 Micron Technology, Inc. All rights reserved.

from libc.stdint cimport uint64_t
# Avoid interfering with Python bool type since Cython seems to struggle
# differentiating the 2
from libcpp cimport bool as cbool
from libc.stdlib cimport calloc


cdef extern from "hse/hse.h":
    ctypedef uint64_t hse_err_t
    cdef struct hse_params:
        pass
    cdef struct hse_kvdb:
        pass
    cdef struct hse_kvs:
        pass
    cdef struct hse_kvs_cursor:
        pass
    cdef struct hse_kvdb_txn:
        pass
    cdef struct hse_kvdb_opspec:
        unsigned int  kop_opaque
        unsigned int  kop_flags
        hse_kvdb_txn *kop_txn

    cdef int HSE_KVDB_KOP_FLAG_REVERSE
    cdef int HSE_KVDB_KOP_FLAG_BIND_TXN
    cdef int HSE_KVDB_KOP_FLAG_STATIC_VIEW
    cdef int HSE_KVDB_KOP_FLAG_PRIORITY

    cdef int hse_err_to_errno(hse_err_t err)
    cdef char *hse_err_to_string(hse_err_t err, char *buf, size_t buf_len, size_t *need_len)

    const char *hse_kvdb_version_string()
    const char *hse_kvdb_version_tag()
    const char *hse_kvdb_version_sha()

    hse_err_t hse_init()
    void hse_fini()

    hse_err_t hse_kvdb_make(const char *mp_name, const hse_params *params)
    hse_err_t hse_kvdb_open(const char *mp_name, const hse_params *params, hse_kvdb **kvdb)
    hse_err_t hse_kvdb_close(hse_kvdb *kvdb)
    hse_err_t hse_kvdb_get_names(hse_kvdb *kvdb, unsigned int *count, char ***kvs_list) nogil
    void hse_kvdb_free_names(hse_kvdb *kvdb, char **kvs_list) nogil
    hse_err_t hse_kvdb_kvs_make(hse_kvdb *kvdb, const char *kvs_name, const hse_params *params)
    hse_err_t hse_kvdb_kvs_drop(hse_kvdb *kvdb, const char *kvs_name)
    hse_err_t hse_kvdb_kvs_open(
        hse_kvdb            *kvdb,
        const char          *kvs_name,
        const hse_params    *params,
        hse_kvs            **kvs_out)
    hse_err_t hse_kvdb_kvs_close(hse_kvs *kvs)

    hse_err_t hse_kvs_put(
        hse_kvs         *kvs,
        hse_kvdb_opspec *opspec,
        const void      *key,
        size_t           key_len,
        const void      *val,
        size_t           val_len) nogil
    hse_err_t hse_kvs_get(
        hse_kvs         *kvs,
        hse_kvdb_opspec *opspec,
        const void      *key,
        size_t           key_len,
        cbool           *found,
        void            *buf,
        size_t           buf_len,
        size_t          *val_len) nogil
    hse_err_t hse_kvs_delete(
        hse_kvs         *kvs,
        hse_kvdb_opspec *opspec,
        const void      *key,
        size_t           key_len) nogil
    hse_err_t hse_kvs_prefix_delete(
        hse_kvs         *kvs,
        hse_kvdb_opspec *opspec,
        const void      *filt,
        size_t           filt_len,
        size_t          *kvs_pfx_len) nogil

    cdef enum hse_kvdb_txn_state:
        HSE_KVDB_TXN_INVALID,
        HSE_KVDB_TXN_ACTIVE,
        HSE_KVDB_TXN_COMMITTED,
        HSE_KVDB_TXN_ABORTED

    hse_err_t hse_kvdb_sync(hse_kvdb *kvdb) nogil
    hse_err_t hse_kvdb_flush(hse_kvdb *kvdb) nogil

    cdef int HSE_KVDB_COMP_FLAG_CANCEL
    cdef int HSE_KVDB_COMP_FLAG_SAMP_LWM

    hse_err_t hse_kvdb_compact(hse_kvdb *kvdb, int flags) nogil

    cdef struct hse_kvdb_compact_status:
        unsigned int kvcs_samp_lwm
        unsigned int kvcs_samp_hwm
        unsigned int kvcs_samp_curr
        unsigned int kvcs_active
        unsigned int kvcs_canceled

    hse_err_t hse_kvdb_compact_status_get(hse_kvdb *kvdb, hse_kvdb_compact_status *status) nogil

    hse_kvdb_txn *hse_kvdb_txn_alloc(hse_kvdb *kvdb) nogil
    void hse_kvdb_txn_free(hse_kvdb *kvdb, hse_kvdb_txn *txn) nogil
    hse_err_t hse_kvdb_txn_begin(hse_kvdb *kvdb, hse_kvdb_txn *txn) nogil
    hse_err_t hse_kvdb_txn_commit(hse_kvdb *kvdb, hse_kvdb_txn *txn) nogil
    hse_err_t hse_kvdb_txn_abort(hse_kvdb *kvdb, hse_kvdb_txn *txn) nogil
    hse_kvdb_txn_state hse_kvdb_txn_get_state(hse_kvdb *kvdb, hse_kvdb_txn *txn) nogil

    hse_err_t hse_kvs_cursor_create(
        hse_kvs         *kvs,
        hse_kvdb_opspec *opspec,
        const void      *filt,
        size_t           filt_len,
        hse_kvs_cursor **cursor) nogil
    hse_err_t hse_kvs_cursor_update(hse_kvs_cursor *cursor, hse_kvdb_opspec *opspec) nogil
    hse_err_t hse_kvs_cursor_seek(
        hse_kvs_cursor  *cursor,
        hse_kvdb_opspec *opspec,
        const void      *key,
        size_t           key_len,
        const void     **found,
        size_t          *found_len) nogil
    hse_err_t hse_kvs_cursor_seek_range(
        hse_kvs_cursor  *cursor,
        hse_kvdb_opspec *opspec,
        const void      *filt_min,
        size_t           filt_min_len,
        const void      *filt_max,
        size_t           filt_max_len,
        const void     **found,
        size_t          *found_len) nogil
    hse_err_t hse_kvs_cursor_read(
        hse_kvs_cursor  *cursor,
        hse_kvdb_opspec *opspec,
        const void     **key,
        size_t          *key_len,
        const void     **val,
        size_t          *val_len,
        cbool           *eof) nogil
    hse_err_t hse_kvs_cursor_destroy(hse_kvs_cursor *cursor) nogil

    hse_err_t hse_params_create(hse_params **params)
    void hse_params_destroy(hse_params *params)
    hse_err_t hse_params_from_file(hse_params *params, const char *path)
    hse_err_t hse_params_from_string(hse_params *params, const char *input)
    hse_err_t hse_params_set(hse_params *params, const char *key, const char *val)
    char *hse_params_get(
        const hse_params 	*params,
        const char          *key,
        char                *buf,
        size_t               buf_len,
        size_t              *param_len)


cdef inline hse_kvdb_opspec *HSE_KVDB_OPSPEC_INIT() except NULL:
    cdef hse_kvdb_opspec *opspec = <hse_kvdb_opspec *>calloc(1, sizeof(hse_kvdb_opspec))
    if not opspec:
        raise MemoryError()

    opspec.kop_opaque = 0xb0de0001

    return opspec


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


cdef class Params:
    cdef hse_params *_c_hse_params
