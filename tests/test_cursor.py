# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2020-2021 Micron Technology, Inc. All rights reserved.

from typing import Generator, Optional, Union
from hse2 import hse
import pytest
import errno


@pytest.fixture(scope="module")
def kvs(kvdb: hse.Kvdb) -> Generator[hse.Kvs, None, None]:
    try:
        kvdb.kvs_create("cursor-test", "prefix.length=3")
    except hse.HseException as e:
        if e.returncode == errno.EEXIST:
            pass
        else:
            raise e
    kvs = kvdb.kvs_open("cursor-test", "transactions.enabled=false")

    yield kvs

    kvs.close()
    kvdb.kvs_drop("cursor-test")


@pytest.fixture(scope="function", autouse=True)
def kvs_setup(kvs: hse.Kvs):
    for i in range(5):
        kvs.put(f"key{i}", f"value{i}")
    yield
    kvs.prefix_delete(b"key")


@pytest.mark.parametrize(
    "filter,key", [(None, b"key3"), ("key", "key3"), (b"key", b"key3")]
)
def test_seek(
    kvs: hse.Kvs, filter: Optional[Union[str, bytes]], key: Union[str, bytes]
):
    with kvs.cursor(filter) as cursor:
        found = cursor.seek(key)
        assert found == b"key3"
        kv = cursor.read()
        assert kv == (b"key3", b"value3")
        cursor.read()
        cursor.read()
        cursor.read()
        assert cursor.eof


@pytest.mark.parametrize(
    "filter,filt_min,filt_max",
    [(None, "key0", "key3"), ("key", "key0", "key3"), (b"key", b"key0", b"key3")],
)
def test_seek_range(
    kvs: hse.Kvs,
    filter: Optional[Union[str, bytes]],
    filt_min: Union[str, bytes],
    filt_max: Union[str, bytes],
):
    with kvs.cursor(filter) as cursor:
        found = cursor.seek_range(filt_min, filt_max)
        assert found == b"key0"
        kv = cursor.read()
        assert kv == (b"key0", b"value0")
        cursor.read()
        cursor.read()
        kv = cursor.read()
        assert kv == (b"key3", b"value3")
        cursor.read()
        assert cursor.eof


@pytest.mark.parametrize("reverse", [(0), (hse.CursorCreateFlag.REV)])
def test_update_view(kvs: hse.Kvs, reverse: hse.CursorCreateFlag):
    with kvs.cursor(flags=reverse) as cursor:
        kvs.put(b"key5", b"value5")

        assert sum(1 for _ in cursor.items()) == 5
        assert cursor.read() == (None, None)

        cursor.update_view()

        kv = cursor.read()
        if not reverse:
            assert kv == (b"key5", b"value5")
        else:
            assert cursor.eof
        cursor.read()
        assert cursor.eof


def test_reverse(kvs: hse.Kvs):
    with kvs.cursor(flags=hse.CursorCreateFlag.REV) as cursor:
        for i in reversed(range(5)):
            assert (
                cursor.read() == (f"key{i}".encode(), f"value{i}".encode())
                and not cursor.eof
            )
