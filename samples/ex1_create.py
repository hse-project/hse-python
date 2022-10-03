#!/usr/bin/env python3

# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2020-2022 Micron Technology, Inc. All rights reserved.

import sys

from hse3 import hse


def main() -> int:
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <home> <kvs1> [<kvs2> ... <kvsN>")
        return 1

    kvdb_home = sys.argv[1]
    kvs_list = sys.argv[2:]

    hse.Kvdb.create(kvdb_home)
    kvdb = hse.Kvdb.open(kvs_list)
    for kvs in kvs_list:
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
