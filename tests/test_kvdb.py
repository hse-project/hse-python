import hse
import pytest
from typing import Generator
import errno


@pytest.fixture(scope="module")
def kvs(kvdb: hse.Kvdb) -> Generator[hse.Kvs, None, None]:
    try:
        kvdb.kvs_create("kvdb-test", "pfx_len=3")
    except hse.KvdbException as e:
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


def test_flush(kvdb: hse.Kvdb):
    kvdb.flush()


@pytest.mark.skip(reason="Hard to control when compaction occurs")
def test_compact(kvdb: hse.Kvdb, kvs: hse.Kvs):
    for i in range(1000):
        kvs.put(f"key{i}".encode(), f"value{i}".encode())
    kvdb.compact()
    status = kvdb.compact_status
    assert status.active
    kvdb.compact(cancel=True)
    status = kvdb.compact_status
    assert status.canceled
