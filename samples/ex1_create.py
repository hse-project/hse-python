#!/usr/bin/env python3

# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2020-2021 Micron Technology, Inc. All rights reserved.

from hse2 import hse
import sys


def main() -> int:
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <home> <kvs1> [<kvs2> ... <kvsN>")
        return 1

    KVDB_HOME = sys.argv[1]
    KVS_LIST = sys.argv[2:]

    hse.Kvdb.create(KVDB_HOME)
    kvdb = hse.Kvdb.open(KVDB_HOME)
    for kvs in KVS_LIST:
        kvdb.kvs_create(kvs)

    print("KVDB and KVSes created")

    kvdb.close()

    return 0


if __name__ == "__main__":
    hse.init()
    try:
        main()
    finally:
        hse.fini()
