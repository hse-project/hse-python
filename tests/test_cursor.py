# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2020-2021 Micron Technology, Inc. All rights reserved.

from typing import Generator, Optional
from hse2 import hse
import pytest
import errno


@pytest.fixture(scope="module")
def kvs(kvdb: hse.Kvdb) -> Generator[hse.Kvs, None, None]:
    try:
        kvdb.kvs_create("cursor-test", "pfx_len=3")
    except hse.HseException as e:
        if e.returncode == errno.EEXIST:
            pass
        else:
            raise e
    kvs = kvdb.kvs_open("cursor-test", "transactions_enable=0")

    yield kvs

    kvs.close()
    kvdb.kvs_drop("cursor-test")


@pytest.fixture(scope="function", autouse=True)
def kvs_setup(kvs: hse.Kvs):
    for i in range(5):
        kvs.put(f"key{i}".encode(), f"value{i}".encode())
    yield
    kvs.prefix_delete(b"key")


@pytest.mark.parametrize("filter", [(None), (b"key")])
def test_seek(kvs: hse.Kvs, filter: Optional[bytes]):
    with kvs.cursor(filter) as cursor:
        found = cursor.seek(b"key3")
        assert found == b"key3"
        kv = cursor.read()
        assert kv == (b"key3", b"value3")
        cursor.read()
        cursor.read()
        cursor.read()
        assert cursor.eof


@pytest.mark.parametrize("filter", [(None), (b"key")])
def test_seek_range(kvs: hse.Kvs, filter: Optional[bytes]):
    with kvs.cursor(filter) as cursor:
        found = cursor.seek_range(b"key0", b"key3")
        assert found == b"key0"
        kv = cursor.read()
        assert kv == (b"key0", b"value0")
        cursor.read()
        cursor.read()
        kv = cursor.read()
        assert kv == (b"key3", b"value3")
        cursor.read()
        assert cursor.eof


@pytest.mark.parametrize("reverse", [(0), (hse.CursorFlag.REVERSE)])
def test_update(kvs: hse.Kvs, reverse: hse.CursorFlag):
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
    with kvs.cursor(flags=hse.CursorFlag.REVERSE) as cursor:
        for i in reversed(range(5)):
            assert (
                cursor.read() == (f"key{i}".encode(), f"value{i}".encode())
                and not cursor.eof
            )
