# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2020 Micron Technology, Inc. All rights reserved.

cdef extern from "hse/hse_limits.h":
    cdef int HSE_KVS_COUNT_MAX
    cdef int HSE_KVS_KLEN_MAX
    cdef int HSE_KVS_VLEN_MAX
    cdef int HSE_KVS_MAX_PFXLEN
    cdef int HSE_KVS_NAME_LEN_MAX
