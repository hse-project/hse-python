import hse


def test_limits():
    assert hse.limits.KVS_COUNT_MAX
    assert hse.limits.KVS_KEY_LEN_MAX
    assert hse.limits.KVS_VALUE_LEN_MAX
    assert hse.limits.KVS_PFX_LEN_MAX
    assert hse.limits.KVS_NAME_LEN_MAX
