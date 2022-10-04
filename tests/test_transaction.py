# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2020-2022 Micron Technology, Inc. All rights reserved.

import unittest

from common import ARGS, UNKNOWN, HseTestCase, kvdb_fixture

from hse3 import hse


class TransactionsTests(HseTestCase):
    @classmethod
    def setUpClass(cls) -> None:
        super().setUpClass()

        cls.kvdb = kvdb_fixture()

    @classmethod
    def tearDownClass(cls) -> None:
        cls.kvdb.close()
        hse.Kvdb.drop(ARGS.home)

        return super().tearDownClass()

    def test_state_transitions(self):
        txn = self.kvdb.transaction()
        self.assertEqual(txn.state, hse.KvdbTransactionState.INVALID)
        txn.begin()
        self.assertEqual(txn.state, hse.KvdbTransactionState.ACTIVE)
        txn.abort()
        self.assertEqual(txn.state, hse.KvdbTransactionState.ABORTED)
        txn.begin()
        txn.commit()
        self.assertEqual(txn.state, hse.KvdbTransactionState.COMMITTED)


if __name__ == "__main__":
    unittest.main(argv=UNKNOWN)
