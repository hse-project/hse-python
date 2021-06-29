# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2020-2021 Micron Technology, Inc. All rights reserved.

from hse cimport hse_err_t, hse_kvdb, hse_kvs, hse_kvdb_txn


cdef extern from "hse/hse_experimental.h":
    cdef enum hse_kvs_pfx_probe_cnt:
        HSE_KVS_PFX_FOUND_ZERO,
        HSE_KVS_PFX_FOUND_ONE,
        HSE_KVS_PFX_FOUND_MUL

    hse_err_t hse_kvs_prefix_probe_exp(
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
