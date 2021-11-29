# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2021 Micron Technology, Inc. All rights reserved.

import pytest
from hse2 import hse


def test_param():
    assert hse.param("socket.enabled") == "false"


@pytest.mark.xfail(strict=True)
def test_bad_param():
    hse.param("this-does-not-exist")
