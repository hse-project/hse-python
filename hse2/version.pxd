# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2021 Micron Technology, Inc. All rights reserved.

cdef extern from "hse/version.h":
    cdef const char *HSE_VERSION_STRING
    cdef unsigned int HSE_VERSION_MAJOR
    cdef unsigned int HSE_VERSION_MINOR
    cdef unsigned int HSE_VERSION_PATCH
