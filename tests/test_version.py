import hse


def test_version():
    assert hse.version.STRING != None
    assert hse.version.TAG != None
    assert hse.version.SHA != None
    assert hse.version.MAJOR != None
    assert hse.version.MINOR != None
    assert hse.version.PATCH != None
