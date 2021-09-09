# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2020-2021 Micron Technology, Inc. All rights reserved.

from hse2 import version


def test_version():
    assert version.STRING is not None
    assert version.MAJOR is not None
    assert version.MINOR is not None
    assert version.PATCH is not None
