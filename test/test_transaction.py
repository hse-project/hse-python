from hse.hse import TransactionState
import hse


def test_state_transitions(kvdb: hse.Kvdb):
    txn = kvdb.transaction()
    assert txn.state == TransactionState.INVALID
    txn.begin()
    assert txn.state == TransactionState.ACTIVE
    txn.abort()
    assert txn.state == TransactionState.ABORTED
    txn.begin()
    txn.commit()
    assert txn.state == TransactionState.COMMITTED
