from typing import Optional
import hse
import pytest
import errno


@pytest.fixture(scope="module")
def kvs(kvdb: hse.Kvdb):
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


@pytest.mark.parametrize("filter", [(None), (b"key")])
def test_seek(kvs: hse.Kvs, filter: Optional[bytes]):
    for i in range(5):
        kvs.put(f"key{i}".encode(), f"value{i}".encode())

    with kvs.cursor(filter) as cursor:
        found = cursor.seek(b"key3")
        assert found == b"key3"
        *kv, _ = cursor.read()
        assert kv == [b"key3", b"value3"]
        cursor.read()
        cursor.read()
        *_, eof = cursor.read()
        assert eof

    kvs.prefix_delete(b"key")


@pytest.mark.parametrize("filter", [(None), (b"key")])
def test_seek_range(kvs: hse.Kvs, filter: Optional[bytes]):
    for i in range(5):
        kvs.put(f"key{i}".encode(), f"value{i}".encode())

    with kvs.cursor(filter) as cursor:
        found = cursor.seek_range(b"key0", b"key3")
        assert found == b"key0"
        *kv, _ = cursor.read()
        assert kv == [b"key0", b"value0"]
        cursor.read()
        cursor.read()
        *kv, _ = cursor.read()
        assert kv == [b"key3", b"value3"]
        *_, eof = cursor.read()
        assert eof

    kvs.prefix_delete(b"key")


def test_update(kvs: hse.Kvs):
    for i in range(5):
        kvs.put(f"key{i}".encode(), f"value{i}".encode())

    with kvs.cursor() as cursor:
        kvs.put(b"key5", b"value5")

        assert sum(1 for _ in cursor.items()) == 5
        assert cursor.read() == (None, None, True)

        cursor.update()

        *kv, _ = cursor.read()
        assert kv == [b"key5", b"value5"]
        *_, eof = cursor.read()
        assert eof

    kvs.prefix_delete(b"key")


def test_reverse(kvs: hse.Kvs):
    for i in range(5):
        kvs.put(f"key{i}".encode(), f"value{i}".encode())

    with kvs.cursor(reverse=True) as cursor:
        for i in reversed(range(5)):
            assert cursor.read() == (f"key{i}".encode(), f"value{i}".encode(), False)

    kvs.prefix_delete(b"key")
