# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2020-2021 Micron Technology, Inc. All rights reserved.

import hse
from enum import Enum
from typing import Tuple, Optional
cimport experimental
cimport limits
cimport hse
from libc.stdlib cimport free


class KvsPfxProbeCnt(Enum):
    """
    @SUB@ experimental.KvsPfxProbeCnt.__doc__
    """
    ZERO = experimental.HSE_KVS_PFX_FOUND_ZERO
    ONE = experimental.HSE_KVS_PFX_FOUND_ONE
    MUL = experimental.HSE_KVS_PFX_FOUND_MUL


def kvs_prefix_probe(
        hse.Kvs kvs,
        const unsigned char [:]pfx,
        hse.Transaction txn=None,
        unsigned char [:]key_buf=bytearray(limits.HSE_KVS_KEY_LEN_MAX),
        unsigned char [:]value_buf=bytearray(limits.HSE_KVS_VALUE_LEN_MAX),
    ) -> Tuple[KvsPfxProbeCnt, Optional[bytes], Optional[bytes]]:
    """
    @SUB@ experimental.kvs_prefix_probe.__doc__
    """
    cnt, key, _, value, _ = kvs_prefix_probe_with_lengths(kvs, pfx, txn, key_buf, value_buf)
    return (
        cnt,
        key,
        value
    )


def kvs_prefix_probe_with_lengths(
        hse.Kvs kvs,
        const unsigned char [:]pfx,
        hse.Transaction txn=None,
        unsigned char [:]key_buf=bytearray(limits.HSE_KVS_KEY_LEN_MAX),
        unsigned char [:]value_buf=bytearray(limits.HSE_KVS_VALUE_LEN_MAX),
        **kwargs
    ) -> Tuple[KvsPfxProbeCnt, Optional[bytes], int, Optional[bytes], int]:
    """
    @SUB@ experimental.kvs_prefix_probe_with_lengths.__doc__
    """
    cdef hse_kvdb_txn *txn_addr = NULL
    cdef const void *pfx_addr = NULL
    cdef size_t pfx_len = 0
    cdef experimental.hse_kvs_pfx_probe_cnt found = experimental.HSE_KVS_PFX_FOUND_ZERO
    cdef void *key_buf_addr = NULL
    cdef size_t key_buf_len = 0
    cdef size_t key_len = 0
    cdef void *value_buf_addr = NULL
    cdef size_t value_buf_len = 0
    cdef size_t value_len = 0
    if pfx is not None and len(pfx) > 0:
        pfx_addr = &pfx[0]
        pfx_len = len(pfx)
    if key_buf is not None and len(key_buf) > 0:
        key_buf_addr = &key_buf[0]
        key_buf_len = len(key_buf)
    if value_buf is not None and len(value_buf) > 0:
        value_buf_addr = &value_buf[0]
        value_buf_len = len(value_buf)
    if txn:
        txn_addr = txn._c_hse_kvdb_txn

    cdef hse.hse_err_t err = 0
    with nogil:
        err = experimental.hse_kvs_prefix_probe_exp(kvs._c_hse_kvs, 0, txn_addr,
            pfx_addr, pfx_len, &found, key_buf_addr, key_buf_len, &key_len,
            value_buf_addr, value_buf_len, &value_len)
    if err != 0:
        raise hse.KvdbException(err)
    if found == experimental.HSE_KVS_PFX_FOUND_ZERO:
        return KvsPfxProbeCnt.ZERO, None, 0, None, 0

    return (
        KvsPfxProbeCnt(found),
        bytes(key_buf)[:key_len] if key_buf is not None and key_len < len(key_buf) else key_buf,
        key_len,
        bytes(value_buf)[:value_len] if value_buf is not None and value_len < len(value_buf) else value_buf,
        value_len
    )
