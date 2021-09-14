# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2020-2021 Micron Technology, Inc. All rights reserved.

import errno
from typing import Generator, SupportsBytes, Union
from hse2 import hse
import pytest


class Key(SupportsBytes):
    def __init__(self, key: str) -> None:
        self.__key = key

    def __bytes__(self) -> bytes:
        return self.__key.encode()


class Value(SupportsBytes):
    def __init__(self, value: str) -> None:
        self.__value = value

    def __bytes__(self) -> bytes:
        return self.__value.encode()


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


@pytest.mark.parametrize(
    "key,value",
    [
        ("key1", "value"),
        (b"key1", b"value"),
        (Key("key1"), Value("value")),
    ],
)
def test_key_operations(kvs: hse.Kvs, key: Union[str, bytes, SupportsBytes], value: Union[str, bytes, SupportsBytes]):
    kvs.put(key, value)
    assert kvs.get(key)[0] == b"value"

    buf = bytearray(5)
    assert kvs.get(key, buf=buf)[0] == b"value"

    kvs.delete(key)
    assert kvs.get(key)[0] == None


@pytest.mark.parametrize(
    "pfx",
    ["key", b"key"],
)
def test_prefix_delete(kvs: hse.Kvs, pfx: Union[str, bytes]):
    for i in range(5):
        kvs.put(f"key{i}", f"value{i}")

    assert kvs.prefix_delete(pfx) == 3

    for i in range(5):
        assert kvs.get(f"key{i}")[0] == None


def test_get_with_length(kvs: hse.Kvs):
    kvs.put(b"key1", b"value")
    assert kvs.get(b"key1") == (b"value", 5)
    assert kvs.get(b"key1", buf=None) == (None, 5)
    kvs.delete(b"key1")


@pytest.mark.experimental
@pytest.mark.parametrize("pfx1,pfx2", [("key", "abc"), (b"key", b"abc")])
def test_prefix_probe(kvs: hse.Kvs, pfx1: Union[str, bytes], pfx2: Union[str, bytes]):
    kvs.put(b"key1", b"value1")
    kvs.put(b"abc1", b"value1")
    kvs.put(b"abc2", b"value2")

    cnt, k, _, v, _ = kvs.prefix_probe(pfx1)
    assert cnt == hse.KvsPfxProbeCnt.ONE
    assert (k, v) == (b"key1", b"value1")

    cnt, k, kl, v, vl = kvs.prefix_probe(pfx2)
    assert cnt == hse.KvsPfxProbeCnt.MUL
    assert (k, v) == (b"abc1", b"value1")
    assert kl == 4
    assert vl == 6

    cnt, *_ = kvs.prefix_probe("xyz")
    assert cnt == hse.KvsPfxProbeCnt.ZERO

    kvs.prefix_delete(b"key")


@pytest.mark.xfail(strict=True)
def test_none_put(kvs: hse.Kvs):
    kvs.put(None, None)  # type: ignore


@pytest.mark.xfail(strict=True)
def test_none_get(kvs: hse.Kvs):
    kvs.get(None)  # type: ignore


@pytest.mark.xfail(strict=True)
def test_none_delete(kvs: hse.Kvs):
    kvs.delete(None)  # type: ignore


@pytest.mark.xfail(strict=True)
def test_none_prefix_delete(kvs: hse.Kvs):
    kvs.prefix_delete(None)  # type: ignore
