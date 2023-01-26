# SPDX-License-Identifier: Apache-2.0 OR MIT
#
# SPDX-FileCopyrightText: Copyright 2020 Micron Technology, Inc.

import unittest

from common import UNKNOWN

from hse3 import version


class VersionTests(unittest.TestCase):
    def test_string(self):
        self.assertIsNotNone(version.STRING)

    def test_major(self):
        self.assertIsNotNone(version.MAJOR)

    def test_minor(self):
        self.assertIsNotNone(version.MINOR)

    def test_patch(self):
        self.assertIsNotNone(version.PATCH)


if __name__ == "__main__":
    unittest.main(argv=UNKNOWN)
