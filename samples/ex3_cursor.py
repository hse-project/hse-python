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

    for i in range(15):
        kvs.put(f"key{i:03}".encode(), f"val{i:03}".encode())

    with kvs.cursor() as cursor:
        while not cursor.eof:
            key, val = cursor.read()
            if not cursor.eof:
                print(
                    f"key: {key.decode() if key else None}\tval: {val.decode() if val else None}"
                )

        cursor.seek(b"key010")
        key, val = cursor.read()

        print("After seek to key010:")
        print("expected: key: key010\tval: val010")
        print(
            f"found   : key: {key.decode() if key else None}\tval: {val.decode() if val else None}"
        )

    kvs.close()
    kvdb.close()

    return 0


if __name__ == "__main__":
    hse.init()
    try:
        main()
    finally:
        hse.fini()
