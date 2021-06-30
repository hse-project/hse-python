# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2020 Micron Technology, Inc. All rights reserved.

cdef extern from "hse/hse_limits.h":
    cdef size_t HSE_KVS_COUNT_MAX
    cdef size_t HSE_KVS_KEY_LEN_MAX
    cdef size_t HSE_KVS_VALUE_LEN_MAX
    cdef size_t HSE_KVS_PFX_LEN_MAX
    cdef size_t HSE_KVS_NAME_LEN_MAX
