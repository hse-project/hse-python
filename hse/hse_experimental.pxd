# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2020 Micron Technology, Inc. All rights reserved.

from hse cimport hse_err_t, hse_kvdb, hse_params, hse_kvs, hse_kvdb_opspec


cdef extern from "hse/hse_experimental.h":
    hse_err_t hse_kvdb_export_exp(hse_kvdb *handle, hse_params *params, const char *path)
    hse_err_t hse_kvdb_import_exp(const char *mpool_name, const char *path)

    cdef enum hse_kvs_pfx_probe_cnt:
        HSE_KVS_PFX_FOUND_ZERO,
        HSE_KVS_PFX_FOUND_ONE,
        HSE_KVS_PFX_FOUND_MUL

    hse_err_t hse_kvs_prefix_probe_exp(
        hse_kvs *              kvs,
        hse_kvdb_opspec *      os,
        const void *           pfx,
        size_t                 pfx_len,
        hse_kvs_pfx_probe_cnt *found,
        void *                 keybuf,
        size_t                 keybuf_sz,
        size_t *               key_len,
        void *                 valbuf,
        size_t                 valbuf_sz,
        size_t *               val_len) nogil

    char *hse_params_err_exp(const hse_params *params, char *buf, size_t buf_sz)
