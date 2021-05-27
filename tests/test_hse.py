import hse


def test_version():
    assert hse.KVDB_VERSION_STRING != None
    assert hse.KVDB_VERSION_TAG != None
    assert hse.KVDB_VERSION_SHA != None
