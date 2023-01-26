# SPDX-License-Identifier: Apache-2.0 OR MIT
#
# SPDX-FileCopyrightText: Copyright 2020 Micron Technology, Inc.

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
