#!/usr/bin/env python3

import hse
import sys


def main() -> int:
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <mpool> <kvs>")
        return 1

    MPOOL_NAME = sys.argv[1]
    KVS_NAME = sys.argv[2]

    hse.Kvdb.init()

    kvdb = hse.Kvdb.open(MPOOL_NAME)
    kvs = kvdb.kvs_open(KVS_NAME)

    for i in range(15):
        kvs.put(f"key{i:03}".encode(), f"val{i:03}".encode())

    with kvs.cursor_create() as cursor:
        eof = False
        while not eof:
            key, val, eof = cursor.read()
            if not eof:
                print(
                    f"key: {key.decode() if key else None}\tval: {val.decode() if val else None}"
                )

        cursor.seek(b"key010")
        key, val, eof = cursor.read()

        print("After seek to key010:")
        print(f"expected: key: key010\tval: val010")
        print(
            f"found   : key: {key.decode() if key else None}\tval: {val.decode() if val else None}"
        )

    kvdb.close()

    hse.Kvdb.fini()

    return 0


if __name__ == "__main__":
    sys.exit(main())
