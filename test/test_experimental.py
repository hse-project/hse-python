from typing import Optional
import hse
import pytest
import errno


@pytest.fixture(scope="module")
def kvs(kvdb: hse.Kvdb):
    p = hse.Params().set("kvs.pfx_len", "3").set("kvs.sfx_len", "1")

    try:
        kvdb.kvs_make("experimental-test", params=p)
    except hse.KvdbException as e:
        if e.returncode == errno.EEXIST:
            pass
        else:
            raise e
    kvs = kvdb.kvs_open("experimental-test", params=p)

    yield kvs

    kvs.close()
    kvdb.kvs_drop("experimental-test")


@pytest.mark.xfail(strict=True)
def test_params_err():
    p = hse.Params().set("", "")
    hse.experimental.params_err(p)


def test_prefix_probe(kvs: hse.Kvs):
    kvs.put(b"key1", b"value1")

    cnt, *kv = hse.experimental.kvs_prefix_probe(kvs, b"key")
    assert cnt == hse.experimental.KvsPfxProbeCnt.ONE
    assert kv == [b"key1", b"value1"]

    kvs.prefix_delete(b"key")


@pytest.mark.parametrize(
    "key_buf,value_buf",
    [
        (bytearray(hse.limits.KVS_KLEN_MAX), bytearray(256)),
        (bytearray(hse.limits.KVS_KLEN_MAX), None),
    ],
)
def test_prefix_probe_with_lengths(
    kvs: hse.Kvs, key_buf: Optional[bytearray], value_buf: Optional[bytearray]
):
    kvs.put(b"key1", b"value1")

    cnt, _, key_len, _, value_len = hse.experimental.kvs_prefix_probe_with_lengths(
        kvs, b"key", key_buf=key_buf, value_buf=value_buf
    )
    assert cnt == hse.experimental.KvsPfxProbeCnt.ONE
    assert key_len == 4
    assert value_len == 6

    kvs.prefix_delete(b"key")
