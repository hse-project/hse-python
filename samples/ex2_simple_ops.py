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

    hse.Kvdb.make(MPOOL_NAME)
    kvdb = hse.Kvdb.open(MPOOL_NAME)
    kvs = kvdb.kvs_open(KVS_NAME)
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

    hse.Kvdb.fini()

    return 0


if __name__ == "__main__":
    sys.exit(main())
