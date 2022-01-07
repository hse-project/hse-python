# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2020-2021 Micron Technology, Inc. All rights reserved.

import unittest

from common import ARGS, UNKNOWN, kvdb_fixture, kvs_fixture, HseTestCase
from hse2 import hse


class KvdbTests(HseTestCase):
    @classmethod
    def setUpClass(cls) -> None:
        super().setUpClass()

        cls.kvdb = kvdb_fixture()
        cls.kvs = kvs_fixture(cls.kvdb, "kvs", cparams=("prefix.length=3",))

    @classmethod
    def tearDownClass(cls) -> None:
        cls.kvs.close()
        cls.kvdb.kvs_drop("kvs")

        cls.kvdb.close()
        hse.Kvdb.drop(ARGS.home)

        return super().tearDownClass()

    def test_sync(self):
        self.kvdb.sync()

    def test_param(self):
        for args in (
            ("durability.interval_ms", '100'),
            ("this-does-not-exist", None),
        ):
            with self.subTest(param=args[0], value=args[1]):
                if args[1]:
                    self.assertEqual(self.kvdb.param(args[0]), args[1])
                else:
                    with self.assertRaises(hse.HseException):
                        self.kvdb.param(args[0])

    def test_home(self):
        self.assertEqual(self.kvdb.home, ARGS.home)

    def test_mclass_info(self):
        for mclass in hse.Mclass:
            with self.subTest(mclass=mclass):
                if mclass is hse.Mclass.CAPACITY:
                    self.assertEqual(
                        self.kvdb.mclass_info(mclass).path, ARGS.home / "capacity"
                    )
                else:
                    with self.assertRaises(hse.HseException):
                        self.kvdb.mclass_info(mclass)

    def test_mclass_is_configured(self):
        for mclass in hse.Mclass:
            with self.subTest(mclass=mclass):
                self.assertEqual(
                    mclass == hse.Mclass.CAPACITY,
                    self.kvdb.mclass_is_configured(mclass),
                )

    @unittest.skip("Hard to control when compaction occurs")
    @unittest.skipUnless(ARGS.experimental, "KVDB compaction is experimental")
    def test_compact(self):
        for i in range(1000):
            self.kvs.put(f"key{i}".encode(), f"value{i}".encode())
        self.kvdb.compact()
        status = self.kvdb.compact_status
        assert status.active
        self.kvdb.compact(flags=hse.KvdbCompactFlag.CANCEL)
        status = self.kvdb.compact_status
        assert status.canceled

    def test_mclass(self):
        self.assertEqual(str(hse.Mclass.CAPACITY), "capacity")
        self.assertEqual(str(hse.Mclass.STAGING), "staging")
        self.assertEqual(str(hse.Mclass.PMEM), "pmem")


if __name__ == "__main__":
    unittest.main(argv=UNKNOWN)
