# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2020-2021 Micron Technology, Inc. All rights reserved.

from hse2 import version


def test_version():
    assert version.STRING != None
    assert version.TAG != None
    assert version.SHA != None
    assert version.MAJOR != None
    assert version.MINOR != None
    assert version.PATCH != None
