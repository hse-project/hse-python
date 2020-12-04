# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2020 Micron Technology, Inc. All rights reserved.

import hse
from enum import Enum
from typing import Tuple, Optional
cimport hse_experimental
cimport hse_limits
from hse cimport hse
from libc.stdlib cimport free


class ParamsException(Exception):
    """
    @SUB@ experimental.ParamsException.__doc__
    """
    def __init__(self, error: str):
        self.error = error

    def __str__(self):
        return self.error


class KvsPfxProbeCnt(Enum):
    """
    @SUB@ experimental.KvsPfxProbeCnt.__doc__
    """
    ZERO = hse_experimental.HSE_KVS_PFX_FOUND_ZERO
    ONE = hse_experimental.HSE_KVS_PFX_FOUND_ONE
    MUL = hse_experimental.HSE_KVS_PFX_FOUND_MUL


def kvdb_export(hse.Kvdb kvdb, str path, hse.Params params=None) -> None:
    """
    @SUB@ experimental.kvdb_export.__doc__
    """
    cdef hse.hse_params *p = params._c_hse_params if params else NULL
    cdef hse.hse_err_t err = hse_experimental.hse_kvdb_export_exp(kvdb._c_hse_kvdb, p, path.encode())
    if err != 0:
        raise hse.KvdbException(err)


def kvdb_import(str mpool_name, str path) -> None:
    """
    @SUB@ experimental.kvdb_import.__doc__
    """
    cdef hse.hse_err_t err = hse_experimental.hse_kvdb_import_exp(mpool_name.encode(), path.encode())
    if err != 0:
        raise hse.KvdbException(err)


def kvs_prefix_probe(hse.Kvs kvs, const unsigned char [:]pfx, unsigned char [:]key_buf=bytearray(hse_limits.HSE_KVS_KLEN_MAX), unsigned char [:]value_buf=bytearray(hse_limits.HSE_KVS_VLEN_MAX), hse.Transaction txn=None) -> Tuple[KvsPfxProbeCnt, Optional[bytes], Optional[bytes]]:
    """
    @SUB@ experimental.kvs_prefix_probe.__doc__
    """
    cnt, key, _, value, _ = kvs_prefix_probe_with_lengths(kvs, pfx, key_buf, value_buf, txn)
    return (
        cnt,
        key,
        value
    )


def kvs_prefix_probe_with_lengths(hse.Kvs kvs, const unsigned char [:]pfx, unsigned char [:]key_buf=bytearray(hse_limits.HSE_KVS_KLEN_MAX), unsigned char [:]value_buf=bytearray(hse_limits.HSE_KVS_VLEN_MAX), hse.Transaction txn=None) -> Tuple[KvsPfxProbeCnt, Optional[bytes], int, Optional[bytes], int]:
    """
    @SUB@ experimental.kvs_prefix_probe_with_lengths.__doc__
    """
    cdef const void *pfx_addr = NULL
    cdef size_t pfx_len = 0
    cdef hse_experimental.hse_kvs_pfx_probe_cnt found = hse_experimental.HSE_KVS_PFX_FOUND_ZERO
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
    cdef hse.hse_kvdb_opspec *opspec = hse.HSE_KVDB_OPSPEC_INIT() if txn else NULL
    if txn:
        opspec.kop_txn = txn._c_hse_kvdb_txn

    cdef hse.hse_err_t err = 0
    try:
        with nogil:
            err = hse_experimental.hse_kvs_prefix_probe_exp(kvs._c_hse_kvs, opspec, pfx_addr, pfx_len, &found, key_buf_addr, key_buf_len, &key_len, value_buf_addr, value_buf_len, &value_len)
        if err != 0:
            raise hse.KvdbException(err)
        if found == hse_experimental.HSE_KVS_PFX_FOUND_ZERO:
            return found, None, 0, None, 0
    finally:
        if opspec:
            free(opspec)

    return (
        KvsPfxProbeCnt(found),
        bytes(key_buf)[:key_len] if key_buf is not None and key_len < len(key_buf) else key_buf,
        key_len,
        bytes(value_buf)[:value_len] if value_buf is not None and value_len < len(value_buf) else value_buf,
        value_len
    )


# 256 is arbitrary
def params_err(hse.Params params, char [:]buf=bytearray(256)) -> None:
    """
    @SUB@ experimental.params_err.__doc__
    """
    cdef hse.hse_params *p = params._c_hse_params if params else NULL

    cdef char *buf_addr = NULL
    cdef size_t buf_len = 0
    if buf is not None:
        buf_addr = &buf[0]
        buf_len = len(buf)

    cdef char *err = hse_experimental.hse_params_err_exp(p, buf_addr, buf_len)
    if err:
        raise ParamsException(err)
