#!/usr/bin/env python3

import hse
import sys

def main() -> int:
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <mpool> <kvs1> [<kvs2> ... <kvsN>")
        return 1

    MPOOL_NAME = sys.argv[1]
    KVS_LIST = sys.argv[2:]

    hse.Kvdb.init()

    hse.Kvdb.make(MPOOL_NAME)
    kvdb = hse.Kvdb.open(MPOOL_NAME)
    for kvs in KVS_LIST:
        kvdb.kvs_make(kvs)

    print("KVDB and KVSes created")

    kvdb.close()

    hse.Kvdb.fini()

    return 0

if __name__ == "__main__":
    sys.exit(main())
