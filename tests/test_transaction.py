
import hse

def test_state_transitions(kvdb: hse.Kvdb):
    txn = kvdb.transaction()
    assert txn.state == hse.KvdbTransactionState.INVALID
    txn.begin()
    assert txn.state == hse.KvdbTransactionState.ACTIVE
    txn.abort()
    assert txn.state == hse.KvdbTransactionState.ABORTED
    txn.begin()
    txn.commit()
    assert txn.state == hse.KvdbTransactionState.COMMITTED
