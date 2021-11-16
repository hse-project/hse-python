# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2020-2021 Micron Technology, Inc. All rights reserved.

import errno
import pathlib
import pytest
from hse2 import hse
from typing import Generator


@pytest.fixture(scope="module")
def kvs(kvdb: hse.Kvdb) -> Generator[hse.Kvs, None, None]:
    try:
        kvdb.kvs_create("kvdb-test", "prefix.length=3")
    except hse.HseException as e:
        if e.returncode == errno.EEXIST:
            pass
        else:
            raise e
    kvs = kvdb.kvs_open("kvdb-test")

    yield kvs

    kvs.close()
    kvdb.kvs_drop("kvdb-test")


def test_sync(kvdb: hse.Kvdb):
    kvdb.sync()


def test_param(kvdb: hse.Kvdb):
    assert kvdb.param("throttling.init_policy") == '"default"'


@pytest.mark.xfail(strict=True)
def test_bad_param(kvdb: hse.Kvdb):
    kvdb.param("this-does-not-exist")


def test_home(kvdb: hse.Kvdb, home: pathlib.Path):
    assert kvdb.home == home


def test_mclass_info(kvdb: hse.Kvdb):
    for mclass in hse.Mclass:
        if mclass is hse.Mclass.CAPACITY:
            kvdb.mclass_info(mclass)
        else:
            try:
                kvdb.mclass_info(mclass)
                assert False
            except hse.HseException as e:
                assert e.returncode == errno.ENOENT


@pytest.mark.skip(reason="Hard to control when compaction occurs")
def test_compact(kvdb: hse.Kvdb, kvs: hse.Kvs):
    for i in range(1000):
        kvs.put(f"key{i}".encode(), f"value{i}".encode())
    kvdb.compact()
    status = kvdb.compact_status
    assert status.active
    kvdb.compact(flags=hse.KvdbCompactFlag.CANCEL)
    status = kvdb.compact_status
    assert status.canceled


def test_mclass():
    assert str(hse.Mclass.CAPACITY) == "capacity"
    assert str(hse.Mclass.STAGING) == "staging"
    assert str(hse.Mclass.PMEM) == "pmem"
