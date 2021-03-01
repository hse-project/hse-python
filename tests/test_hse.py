import hse


def test_version():
    assert hse.KVDB_VERSION_STRING
    assert hse.KVDB_VERSION_TAG
    assert hse.KVDB_VERSION_SHA
