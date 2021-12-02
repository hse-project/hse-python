# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2021 Micron Technology, Inc. All rights reserved.

import unittest

from hse2 import hse
from common import UNKNOWN


class HseTests(unittest.TestCase):
    def test_param(self):
        for args in (("socket.enabled", "false"), ("this-does-not-exist", None)):
            with self.subTest(param=args[0], value=args[1]):
                if args[1]:
                    self.assertEqual(hse.param(args[0]), args[1])
                else:
                    with self.assertRaises(hse.HseException):
                        hse.param(args[0])


if __name__ == "__main__":
    unittest.main(argv=UNKNOWN)
