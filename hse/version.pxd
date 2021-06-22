# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2021 Micron Technology, Inc. All rights reserved.

cdef extern from "hse/hse_version.h":
    cdef const char *HSE_VERSION_STRING
    cdef const char *HSE_VERSION_TAG
    cdef const char *HSE_VERSION_SHA
    cdef int HSE_VERSION_MAJOR
    cdef int HSE_VERSION_MINOR
    cdef int HSE_VERSION_PATCH
