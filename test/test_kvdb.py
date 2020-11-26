import hse


def test_sync(kvdb: hse.Kvdb):
    kvdb.sync()


def test_flush(kvdb: hse.Kvdb):
    kvdb.flush()


# def test_compact(kvdb: hse.Kvdb):
#     kvdb.compact()
#     status = kvdb.compact_status
#     assert status.active
#     kvdb.compact(cancel=True)
#     status = kvdb.compact_status
#     assert status.canceled
