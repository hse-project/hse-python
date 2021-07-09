# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2021 Micron Technology, Inc. All rights reserved.

"""
STRING:

@SUB@ hse.version.STRING.__doc__

TAG:

@SUB@ hse.version.TAG.__doc__

SHA:

@SUB@ hse.version.SHA.__doc__
"""

STRING = HSE_VERSION_STRING.decode()
TAG = HSE_VERSION_TAG.decode()
SHA = HSE_VERSION_SHA.decode()

MAJOR = HSE_VERSION_MAJOR
MINOR = HSE_VERSION_MINOR
PATCH = HSE_VERSION_PATCH
