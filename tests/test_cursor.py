from typing import Generator, Optional
import hse
import pytest
import errno


@pytest.fixture(scope="module")
def kvs(kvdb: hse.Kvdb) -> Generator[hse.Kvs, None, None]:
    p = hse.Params().set("kvs.pfx_len", "3")

    try:
        kvdb.kvs_make("cursor-test", params=p)
    except hse.KvdbException as e:
        if e.returncode == errno.EEXIST:
            pass
        else:
            raise e
    kvs = kvdb.kvs_open("cursor-test", params=p)

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


@pytest.mark.parametrize("reverse", [(True), (False)])
def test_update(kvs: hse.Kvs, reverse: bool):
    with kvs.cursor(reverse=reverse) as cursor:
        kvs.put(b"key5", b"value5")

        assert sum(1 for _ in cursor.items()) == 5
        assert cursor.read() == (None, None)

        cursor.update(reverse=reverse)

        kv = cursor.read()
        if not reverse:
            assert kv == (b"key5", b"value5")
        else:
            assert cursor.eof
        cursor.read()
        assert cursor.eof


def test_reverse(kvs: hse.Kvs):
    with kvs.cursor(reverse=True) as cursor:
        for i in reversed(range(5)):
            assert (
                cursor.read() == (f"key{i}".encode(), f"value{i}".encode())
                and not cursor.eof
            )


def test_type2(kvdb: hse.Kvdb, kvs: hse.Kvs):
    with kvdb.transaction() as txn:
        kvs.put(b"key5", b"value5")
        kvs.put(b"key6", b"value6", txn=txn)
        with kvs.cursor(txn=txn) as cursor:
            for _ in range(5):
                cursor.read()
            cursor.read()
            assert cursor.eof


def test_update_to_type2(kvdb: hse.Kvdb, kvs: hse.Kvs):
    with kvdb.transaction() as txn:
        kvs.put(b"key5", b"value5")
        kvs.put(b"key6", b"value6", txn=txn)
        with kvs.cursor() as cursor:
            cursor.update(txn=txn)
            for _ in range(5):
                cursor.read()
            cursor.read()
            assert cursor.eof


def test_type3(kvdb: hse.Kvdb, kvs: hse.Kvs):
    with kvdb.transaction() as txn:
        kvs.put(b"key5", b"value5")
        kvs.put(b"key6", b"value6", txn=txn)
        with kvs.cursor(bind_txn=True, txn=txn) as cursor:
            for _ in range(5):
                cursor.read()
            kv = cursor.read()
            assert kv == (b"key6", b"value6")
            cursor.read()
            assert cursor.eof


def test_update_to_type3(kvdb: hse.Kvdb, kvs: hse.Kvs):
    with kvdb.transaction() as txn:
        kvs.put(b"key5", b"value5")
        kvs.put(b"key6", b"value6", txn=txn)
        with kvs.cursor() as cursor:
            cursor.update(bind_txn=True, txn=txn)
            for _ in range(5):
                cursor.read()
            kv = cursor.read()
            assert kv == (b"key6", b"value6")
            cursor.read()
            assert cursor.eof
