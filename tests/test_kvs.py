# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2020-2021 Micron Technology, Inc. All rights reserved.

import errno
from typing import Generator, Optional
from hse2 import hse, limits
import pytest


@pytest.fixture(scope="module")
def kvs(kvdb: hse.Kvdb) -> Generator[hse.Kvs, None, None]:
    try:
        kvdb.kvs_create("kvs-test", "prefix.length=3", "suffix.length=1")
    except hse.HseException as e:
        if e.returncode == errno.EEXIST:
            pass
        else:
            raise e
    kvs = kvdb.kvs_open("kvs-test")

    yield kvs

    kvs.close()
    kvdb.kvs_drop("kvs-test")


def test_key_operations(kvs: hse.Kvs):
    kvs.put(b"key1", b"value")
    assert kvs.get(b"key1") == b"value"

    buf = bytearray(5)
    assert kvs.get(b"key1", buf=buf) == b"value"

    kvs.delete(b"key1")
    assert kvs.get(b"key1") == None


def test_prefix_delete(kvs: hse.Kvs):
    for i in range(5):
        kvs.put(f"key{i}".encode(), f"value{i}".encode())

    assert kvs.prefix_delete(b"key") == 3

    for i in range(5):
        assert kvs.get(f"key{i}".encode()) == None


def test_get_with_length(kvs: hse.Kvs):
    kvs.put(b"key1", b"value")
    assert kvs.get_with_length(b"key1") == (b"value", 5)
    assert kvs.get_with_length(b"key1", buf=None) == (None, 5)
    kvs.delete(b"key1")


@pytest.mark.experimental
def test_prefix_probe(kvs: hse.Kvs):
    kvs.put(b"key1", b"value1")
    kvs.put(b"abc1", b"value1")
    kvs.put(b"abc2", b"value2")

    cnt, *kv = kvs.prefix_probe(b"key")
    assert cnt == hse.KvsPfxProbeCnt.ONE
    assert kv == [b"key1", b"value1"]

    cnt, *kv = kvs.prefix_probe(b"abc")
    assert cnt == hse.KvsPfxProbeCnt.MUL
    assert kv == [b"abc1", b"value1"]

    cnt, *_ = kvs.prefix_probe(b"xyz")
    assert cnt == hse.KvsPfxProbeCnt.ZERO

    kvs.prefix_delete(b"key")


@pytest.mark.experimental
@pytest.mark.parametrize(
    "key_buf,value_buf",
    [
        (bytearray(limits.KVS_KEY_LEN_MAX), bytearray(256)),
        (bytearray(limits.KVS_KEY_LEN_MAX), None),
    ],
)
def test_prefix_probe_with_lengths(
    kvs: hse.Kvs, key_buf: bytearray, value_buf: Optional[bytearray]
):
    kvs.put(b"key1", b"value1")

    cnt, _, key_len, _, value_len = kvs.prefix_probe_with_lengths(
        b"key", key_buf=key_buf, value_buf=value_buf
    )
    assert cnt == hse.KvsPfxProbeCnt.ONE
    assert key_len == 4
    assert value_len == 6

    kvs.prefix_delete(b"key")


@pytest.mark.xfail(strict=True)
def test_none_put(kvs: hse.Kvs):
    kvs.put(None, None) # type: ignore


@pytest.mark.xfail(strict=True)
def test_none_get(kvs: hse.Kvs):
    kvs.get(None) # type: ignore


@pytest.mark.xfail(strict=True)
def test_none_delete(kvs: hse.Kvs):
    kvs.delete(None) # type: ignore


@pytest.mark.xfail(strict=True)
def test_none_prefix_delete(kvs: hse.Kvs):
    kvs.prefix_delete(None) # type: ignore
