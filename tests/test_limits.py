# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2020-2021 Micron Technology, Inc. All rights reserved.

import unittest

from hse2 import limits
from common import UNKNOWN


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
