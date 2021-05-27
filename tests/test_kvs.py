import errno
from typing import Generator
import hse
import pytest


@pytest.fixture(scope="module")
def kvs(kvdb: hse.Kvdb) -> Generator[hse.Kvs, None, None]:
    try:
        kvdb.kvs_make("kvs-test", "pfx_len=3")
    except hse.KvdbException as e:
        if e.returncode == errno.EEXIST:
            pass
        else:
            raise e
    kvs = kvdb.kvs_open("kvs-test")

    yield kvs

    kvs.close()
    kvdb.kvs_drop("kvs-test")


def test_key_operations(kvs: hse.Kvs):
    kvs.put(b"key", b"value")
    assert kvs.get(b"key") == b"value"

    buf = bytearray(5)
    assert kvs.get(b"key", buf=buf) == b"value"

    kvs.delete(b"key")
    assert kvs.get(b"key") == None


def test_prefix_delete(kvs: hse.Kvs):
    for i in range(5):
        kvs.put(f"key{i}".encode(), f"value{i}".encode())

    assert kvs.prefix_delete(b"key") == 3

    for i in range(5):
        assert kvs.get(f"key{i}".encode()) == None


def test_get_with_length(kvs: hse.Kvs):
    kvs.put(b"key", b"value")
    assert kvs.get_with_length(b"key") == (b"value", 5)
    assert kvs.get_with_length(b"key", buf=None) == (None, 5)
    kvs.delete(b"key")


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
