# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2021 Micron Technology, Inc. All rights reserved.

"""
@SUB@ limits

@SUB@ limits.KVS_COUNT_MAX

@SUB@ limits.KVS_KEY_LEN_MAX

@SUB@ limits.KVS_VALUE_LEN_MAX

@SUB@ limits.KVS_PFX_LEN_MAX

@SUB@ limits.KVS_NAME_LEN_MAX
"""

cimport limits

KVS_COUNT_MAX = limits.HSE_KVS_COUNT_MAX
KVS_KEY_LEN_MAX = limits.HSE_KVS_KEY_LEN_MAX
KVS_VALUE_LEN_MAX = limits.HSE_KVS_VALUE_LEN_MAX
KVS_PFX_LEN_MAX = limits.HSE_KVS_PFX_LEN_MAX
KVS_NAME_LEN_MAX = limits.HSE_KVS_NAME_LEN_MAX
