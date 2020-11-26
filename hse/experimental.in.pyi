# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2020 Micron Technology, Inc. All rights reserved.

"""
@SUB@ experimental.__doc__
"""


from typing import Optional, Tuple
from hse import Kvdb, Params, Kvs, KvdbTxn
from enum import Enum


class ParamsException(Exception):
    """
    @SUB@ experimental.ParamsException.__doc__
    """

    def __init__(self, error: str) -> None:
        ...


class KvsPfxProbeCnt(Enum):
    """
    @SUB@ experimental.KvsPfxProbeCnt.__doc__
    """

    ZERO = ...
    ONE = ...
    MUL = ...


def kvdb_export(kvdb: Kvdb, path: str, params: Optional[Params] = ...) -> None:
    """
    @SUB@ experimental.kvdb_export.__doc__
    """
    ...


def kvdb_import(mpool_name: str, path: str) -> None:
    """
    @SUB@ experimental.kvdb_import.__doc__
    """
    ...


def kvs_prefix_probe(
    kvs: Kvs,
    pfx: bytes,
    key_buf: bytearray = ...,
    val_buf: bytearray = ...,
    txn: Optional[KvdbTxn] = ...,
) -> Tuple[KvsPfxProbeCnt, Optional[bytes], Optional[bytes]]:
    """
    @SUB@ experimental.kvs_prefix_probe.__doc__
    """
    ...


def kvs_prefix_probe_with_lengths(
    kvs: Kvs,
    pfx: bytes,
    key_buf: bytearray = ...,
    val_buf: bytearray = ...,
    txn: Optional[KvdbTxn] = ...,
) -> Tuple[KvsPfxProbeCnt, Optional[bytes], int, Optional[bytes], int]:
    """
    @SUB@ experimental.kvs_prefix_probe_with_lengths.__doc__
    """
    ...


def params_err(params: Params, buf: bytearray = ...) -> None:
    """
    @SUB@ experimental.params_err.__doc__
    """
    ...
