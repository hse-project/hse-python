#!/usr/bin/env python3

# SPDX-License-Identifier: Apache-2.0 OR MIT
#
# SPDX-FileCopyrightText: Copyright 2020 Micron Technology, Inc.

import sys

from hse3 import hse


def main() -> int:
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <home> <kvs>")
        return 1

    kvdb_home = sys.argv[1]
    kvs_name = sys.argv[2]

    kvdb = hse.Kvdb.open(kvdb_home)
    kvs = kvdb.kvs_open(kvs_name)

    kvs.put(b"k1", b"val1")
    kvs.put(b"k2", b"val2")
    kvs.put(b"k3", b"val3")
    kvs.put(b"k4", None)

    val1 = kvs.get(b"k1")
    print(f"k1 found = {val1 is not None}")

    val2 = kvs.get(b"k2")
    print(f"k2 found = {val2 is not None}")

    val3 = kvs.get(b"k3")
    print(f"k3 found = {val3 is not None}")

    val4 = kvs.get(b"k4")
    print(f"k4 found = {val4 is not None}")

    kvs.delete(b"k1")
    print("k1 deleted")

    val1 = kvs.get(b"k1")
    print(f"k1 found = {val1 is not None}")

    kvs.close()
    kvdb.close()

    return 0


if __name__ == "__main__":
    hse.init()
    try:
        main()
    finally:
        hse.fini()
