from hse2 import limits


def test_limits():
    assert limits.KVS_COUNT_MAX
    assert limits.KVS_KEY_LEN_MAX
    assert limits.KVS_VALUE_LEN_MAX
    assert limits.KVS_PFX_LEN_MAX
    assert limits.KVS_NAME_LEN_MAX
