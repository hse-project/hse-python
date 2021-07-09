from hse2 import version


def test_version():
    assert version.STRING != None
    assert version.TAG != None
    assert version.SHA != None
    assert version.MAJOR != None
    assert version.MINOR != None
    assert version.PATCH != None
