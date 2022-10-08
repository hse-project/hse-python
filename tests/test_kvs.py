# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2020-2022 Micron Technology, Inc. All rights reserved.

import unittest
from typing import SupportsBytes

from common import ARGS, UNKNOWN, HseTestCase, kvdb_fixture, kvs_fixture

from hse3 import hse


class Key(SupportsBytes):
    def __init__(self, key: str) -> None:
        self.__key = key

    def __bytes__(self) -> bytes:
        return self.__key.encode()


class Value(SupportsBytes):
    def __init__(self, value: str) -> None:
        self.__value = value

    def __bytes__(self) -> bytes:
        return self.__value.encode()


class KvsTests(HseTestCase):
    @classmethod
    def setUpClass(cls) -> None:
        super().setUpClass()

        cls.kvdb = kvdb_fixture()
        cls.kvs = kvs_fixture(
            cls.kvdb, "kvs", cparams=("prefix.length=3",)
        )

    @classmethod
    def tearDownClass(cls) -> None:
        cls.kvs.close()
        cls.kvdb.kvs_drop("kvs")

        cls.kvdb.close()
        hse.Kvdb.drop(ARGS.home)

        return super().tearDownClass()

    def test_basic_operations(self):
        for key, value in (
            ("key1", "value"),
            (b"key1", b"value"),
            (Key("key1"), Value("value")),
        ):
            with self.subTest(type=(type(key), type(value))):
                self.kvs.put(key, value)
                self.assertTupleEqual(self.kvs.get(key), (b"value", 5))

                buf = bytearray(5)
                self.assertTupleEqual(self.kvs.get(key, buf=buf), (b"value", 5))

                self.kvs.delete(key)
                self.assertTupleEqual(self.kvs.get(key), (None, 0))

    def test_prefix_delete(self):
        for pfx in ("key", b"key"):
            with self.subTest(type=type(pfx)):
                for i in range(5):
                    self.kvs.put(f"key{i}", f"value{i}")

                self.kvs.prefix_delete(pfx)

                for i in range(5):
                    self.assertIsNone(self.kvs.get(f"key{i}")[0])

    @unittest.skipUnless(ARGS.experimental, "Kvs.prefix_probe() is experimental")
    def test_prefix_probe(self):
        for pfx1, pfx2 in (("key", "abc"), (b"key", b"abc")):
            with self.subTest(type=type(pfx1)):
                self.kvs.put(b"key1", b"value1")
                self.kvs.put(b"abc1", b"value1")
                self.kvs.put(b"abc2", b"value2")

                cnt, k, _, v, _ = self.kvs.prefix_probe(pfx1)
                self.assertEqual(cnt, hse.KvsPfxProbeCnt.ONE)
                self.assertTupleEqual((k, v), (b"key1", b"value1"))

                cnt, k, kl, v, vl = self.kvs.prefix_probe(pfx2)
                self.assertEqual(cnt, hse.KvsPfxProbeCnt.MUL)

                if k == b"abc1":
                    self.assertEqual(v, b"value1")
                elif k == b"abc2":
                    self.assertEqual(v, b"value2")
                else:
                    self.assertEqual(1, 0)

                self.assertEqual(kl, 4)
                self.assertEqual(vl, 6)

                cnt, *_ = self.kvs.prefix_probe("xyz")
                self.assertEqual(cnt, hse.KvsPfxProbeCnt.ZERO)

                self.kvs.prefix_delete(b"key")

    def test_none_put(self):
        with self.assertRaises(hse.HseException):
            self.kvs.put(None, None)  # type: ignore

    def test_none_get(self):
        with self.assertRaises(hse.HseException):
            self.kvs.get(None)  # type: ignore

    def test_none_delete(self):
        with self.assertRaises(hse.HseException):
            self.kvs.delete(None)  # type: ignore

    def test_none_prefix_delete(self):
        with self.assertRaises(hse.HseException):
            self.kvs.prefix_delete(None)  # type: ignore

    def test_param(self):
        for args in (
            ("transactions.enabled", 'false'),
            ("this-does-not-exist", None),
        ):
            with self.subTest(param=args[0], value=args[1]):
                if args[1]:
                    self.assertEqual(self.kvs.param(args[0]), args[1])
                else:
                    with self.assertRaises(hse.HseException):
                        self.kvs.param(args[0])

    def test_name(self):
        assert self.kvs.name == "kvs"


if __name__ == "__main__":
    unittest.main(argv=UNKNOWN)
