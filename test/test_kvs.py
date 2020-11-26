import errno
import hse
import pytest


@pytest.fixture(scope="module")
def kvs(kvdb: hse.Kvdb):
    p = hse.Params().set("kvs.pfx_len", "3")

    try:
        kvdb.kvs_make("kvs-test", params=p)
    except hse.KvdbException as e:
        if e.returncode == errno.EEXIST:
            pass
        else:
            raise e
    kvs = kvdb.kvs_open("kvs-test", params=p)

    yield kvs

    kvs.close()
    kvdb.kvs_drop("kvs-test")


def test_key_operations(kvdb: hse.Kvdb, kvs: hse.Kvs):
    kvs.put(b"key", b"value")
    assert kvs.get(b"key") == b"value"

    buf = bytearray(5)
    assert kvs.get(b"key", buf=buf) == b"value"

    kvs.delete(b"key")
    assert kvs.get(b"key") == None

    with kvdb.transaction() as txn:
        kvs.put(b"key", b"value", txn=txn)
        assert kvs.get(b"key", txn=txn) == b"value"

        kvs.delete(b"key", txn=txn)
        assert kvs.get(b"key", txn=txn) == None

        txn.abort()


def test_prefix_delete(kvdb: hse.Kvdb, kvs: hse.Kvs):
    for i in range(5):
        kvs.put(f"key{i}".encode(), f"value{i}".encode())

    assert kvs.prefix_delete(b"key") == 3

    for i in range(5):
        assert kvs.get(f"key{i}".encode()) == None

    with kvdb.transaction() as txn:
        for i in range(5):
            kvs.put(f"key{i}".encode(), f"value{i}".encode(), txn=txn)

        assert kvs.prefix_delete(b"key", txn=txn) == 3

        for i in range(5):
            assert kvs.get(f"key{i}".encode(), txn=txn) == f"value{i}".encode()

        txn.abort()

    assert kvs.prefix_delete(b"key") == 3


def test_get_value_length(kvdb: hse.Kvdb, kvs: hse.Kvs):
    kvs.put(b"key", b"value")
    assert kvs.get_value_length(b"key") == (b"value", 5)
    assert kvs.get_value_length(b"key", buf=None) == (None, 5)
    kvs.delete(b"key")

    with kvdb.transaction() as txn:
        kvs.put(b"key2", b"value2", txn=txn)
        assert kvs.get_value_length(b"key2", txn=txn) == (b"value2", 6)
        assert kvs.get_value_length(b"key2", txn=txn, buf=None) == (None, 6)
        txn.abort()


@pytest.mark.xfail(strict=True)
def test_none_put(kvs: hse.Kvs):
    kvs.put(None, None)


@pytest.mark.xfail(strict=True)
def test_none_get(kvs: hse.Kvs):
    kvs.get(None)


@pytest.mark.xfail(strict=True)
def test_none_delete(kvs: hse.Kvs):
    kvs.delete(None)


@pytest.mark.xfail(strict=True)
def test_none_prefix_delete(kvs: hse.Kvs):
    kvs.prefix_delete(None)
