import hse

def test_limits():
    assert hse.limits.KVS_COUNT_MAX
    assert hse.limits.KVS_KLEN_MAX
    assert hse.limits.KVS_VLEN_MAX
    assert hse.limits.KVS_MAX_PFXLEN
    assert hse.limits.KVS_NAME_LEN_MAX
