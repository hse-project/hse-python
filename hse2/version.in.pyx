# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2021 Micron Technology, Inc. All rights reserved.

"""
STRING:

@SUB@ hse.version.STRING

MAJOR:

@SUB@ hse.version.MAJOR

MINOR:

@SUB@ hse.version.MINOR

PATCH:

@SUB@ hse.version.PATCH
"""

STRING = HSE_VERSION_STRING.decode()

MAJOR = HSE_VERSION_MAJOR
MINOR = HSE_VERSION_MINOR
PATCH = HSE_VERSION_PATCH
