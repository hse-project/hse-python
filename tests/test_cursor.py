# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2020-2022 Micron Technology, Inc. All rights reserved.

import unittest

from common import ARGS, UNKNOWN, HseTestCase, kvdb_fixture, kvs_fixture

from hse3 import hse


class CursorTests(HseTestCase):
    @classmethod
    def setUpClass(cls) -> None:
        super().setUpClass()

        cls.kvdb = kvdb_fixture()
        cls.kvs = kvs_fixture(
            cls.kvdb, "kvs", cparams=("prefix.length=3", "suffix.length=1")
        )

    @classmethod
    def tearDownClass(cls) -> None:
        cls.kvs.close()
        cls.kvdb.kvs_drop("kvs")

        cls.kvdb.close()
        hse.Kvdb.drop(ARGS.home)

        return super().tearDownClass()

    def setUp(self) -> None:
        super().setUp()
        for i in range(5):
            self.kvs.put(f"key{i}", f"value{i}")

    def tearDown(self) -> None:
        self.kvs.prefix_delete("key")
        return super().tearDown()

    def test_read(self):
        for key_buf, value_buf in ((None, None), (bytearray(10), bytearray(10))):
            with self.subTest(key_buf=key_buf, value_buf=value_buf):
                with self.kvs.cursor() as cursor:
                    kv = cursor.read(key_buf=key_buf, value_buf=value_buf)
                    self.assertTupleEqual(kv, (b"key0", b"value0"))
                    if key_buf and value_buf:
                        # following asserts satisfy type checker
                        assert kv[0]
                        assert kv[1]
                        self.assertTupleEqual(
                            kv,
                            (
                                bytes(key_buf)[: len(kv[0])],
                                bytes(value_buf)[: len(kv[1])],
                            ),
                        )

    def test_items(self):
        for key_buf, value_buf in ((None, None), (bytearray(10), bytearray(10))):
            with self.subTest(key_buf=key_buf, value_buf=value_buf):
                with self.kvs.cursor() as cursor:
                    for i, kv in enumerate(
                        cursor.items(key_buf=key_buf, value_buf=value_buf)
                    ):

                        self.assertTupleEqual(
                            kv, (f"key{i}".encode(), f"value{i}".encode())
                        )
                        if key_buf and value_buf:
                            # following asserts satisfy type checker
                            assert kv[0]
                            assert kv[1]
                            self.assertTupleEqual(
                                kv,
                                (
                                    bytes(key_buf)[: len(kv[0])],
                                    bytes(value_buf)[: len(kv[1])],
                                ),
                            )

    def test_seek(self):
        for filter, key in ((None, b"key3"), ("key", "key3"), (b"key", b"key3")):
            with self.subTest(filter=filter, key=key):
                with self.kvs.cursor(filter) as cursor:
                    found = cursor.seek(key)
                    self.assertEqual(found, b"key3")
                    kv = cursor.read()
                    self.assertTupleEqual(kv, (b"key3", b"value3"))
                    cursor.read()
                    cursor.read()
                    cursor.read()
                    self.assertTrue(cursor.eof)

    def test_seek_range(self):
        for filter, filt_min, filt_max in (
            (None, "key0", "key3"),
            ("key", "key0", "key3"),
            (b"key", b"key0", b"key3"),
        ):
            with self.subTest(filter=filter, filt_min=filt_min, filt_max=filt_max):
                with self.kvs.cursor(filter) as cursor:
                    found = cursor.seek_range(filt_min, filt_max)
                    self.assertEqual(found, b"key0")
                    kv = cursor.read()
                    self.assertTupleEqual(kv, (b"key0", b"value0"))
                    cursor.read()
                    cursor.read()
                    kv = cursor.read()
                    self.assertTupleEqual(kv, (b"key3", b"value3"))
                    cursor.read()
                    self.assertTrue(cursor.eof)

    def test_update_view(self):
        with self.kvs.cursor() as cursor:
            self.kvs.put(b"key5", b"value5")

            self.assertEqual(sum(1 for _ in cursor.items()), 5)
            kv = cursor.read()
            self.assertTupleEqual(kv, (None, None))

            cursor.update_view()

            kv = cursor.read()
            self.assertTupleEqual(kv, (b"key5", b"value5"))
            cursor.read()
            self.assertTrue(cursor.eof)

    def test_reverse(self):
        with self.kvs.cursor(flags=hse.CursorCreateFlag.REV) as cursor:
            for i in reversed(range(5)):
                assert (
                    cursor.read() == (f"key{i}".encode(), f"value{i}".encode())
                    and not cursor.eof
                )


if __name__ == "__main__":
    unittest.main(argv=UNKNOWN)
