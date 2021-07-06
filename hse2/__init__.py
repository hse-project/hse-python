# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2020 Micron Technology, Inc. All rights reserved.

"""
The HSE library is generally described in other places. The documentation here is
geared towards describing the structure of the HSE API and the specifics of each
entry point's operation.

Terminology:

KVS               - Key-value store, containing zero or more key-value (KV)
                    pairs

KVDB              - Key-value database, comprised of one or more KVSs and
                    defining a transaction domain

key               - A byte string used to uniquely identify values for
                    storage, retrieval, and deletion in a KVS

multi-segment key - A key that is logically divided into N segments (N >= 2),
                    arranged to group related KV pairs when keys are sorted
                    lexicographically

key prefix        - For multi-segment keys, the first K segments (1 <= K < N)
                    that group related KV pairs when keys are sorted lexi-
                    cographically

key prefix length - For multi-segment keys, the length of a key prefix (bytes)

unsegmented key   - A key that is not logically divided into segments
"""

__all__ = ["hse", "limits", "version"]
