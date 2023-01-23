# SPDX-License-Identifier: Apache-2.0 OR MIT
#
# SPDX-FileCopyrightText: Copyright 2020 Micron Technology, Inc.

import unittest

from common import UNKNOWN

from hse3 import limits


class LimitsTests(unittest.TestCase):
    def test_kvs_count_max(self):
        self.assertIsNotNone(limits.KVS_COUNT_MAX)

    def test_kvs_key_len_max(self):
        self.assertIsNotNone(limits.KVS_KEY_LEN_MAX)

    def test_kvs_value_len_max(self):
        self.assertIsNotNone(limits.KVS_VALUE_LEN_MAX)

    def test_kvs_pfx_len_max(self):
        self.assertIsNotNone(limits.KVS_PFX_LEN_MAX)

    def test_kvs_name_max(self):
        self.assertIsNotNone(limits.KVS_NAME_LEN_MAX)


if __name__ == "__main__":
    unittest.main(argv=UNKNOWN)
