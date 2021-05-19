# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2020 Micron Technology, Inc. All rights reserved.

"""
@SUB@ experimental.__doc__
"""

from typing import Optional, Tuple
from hse import Kvdb, Params, Kvs, Transaction
from enum import Enum

class ParamsException(Exception):
    """
    @SUB@ experimental.ParamsException.__doc__
    """

    def __init__(self, error: str) -> None: ...

class KvsPfxProbeCnt(Enum):
    """
    @SUB@ experimental.KvsPfxProbeCnt.__doc__
    """

    ZERO = ...
    ONE = ...
    MUL = ...

def kvs_prefix_probe(
    kvs: Kvs,
    pfx: bytes,
    key_buf: bytearray = ...,
    value_buf: bytearray = ...,
    txn: Optional[Transaction] = ...,
) -> Tuple[KvsPfxProbeCnt, Optional[bytes], Optional[bytes]]:
    """
    @SUB@ experimental.kvs_prefix_probe.__doc__
    """
    ...

def kvs_prefix_probe_with_lengths(
    kvs: Kvs,
    pfx: bytes,
    key_buf: bytearray = ...,
    value_buf: Optional[bytearray] = ...,
    txn: Optional[Transaction] = ...,
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
