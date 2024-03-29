#!/usr/bin/env python3

# SPDX-License-Identifier: Apache-2.0 OR MIT
#
# SPDX-FileCopyrightText: Copyright 2020 Micron Technology, Inc.

import sys

from hse3 import hse


def main() -> int:
    if len(sys.argv) != 4:
        print(f"Usage: {sys.argv[0]} <home> <kvs1> <kvs2>")
        return 1

    kvdb_home = sys.argv[1]
    kvs1_name = sys.argv[2]
    kvs2_name = sys.argv[3]

    # Open the KVDB and the KVS instances in it
    kvdb = hse.Kvdb.open(kvdb_home)
    kvs1 = kvdb.kvs_open(kvs1_name)
    kvs2 = kvdb.kvs_open(kvs2_name)

    with kvdb.transaction() as txn:
        kvs1.put(b"k1", b"val1", txn=txn)
        kvs2.put(b"k2", b"val2", txn=txn)

        # This txn hasn't been committed or aborted yet, so we should be able
        # to see the keys from inside the txn, but not from outside.
        val1 = kvs1.get(b"k1", txn=txn)
        print(f"k1 from inside txn: found = {val1 is not None}")
        val1 = kvs1.get(b"k1")
        print(f"k1 from outside txn: found = {val1 is not None}")

        txn.commit()

        # Reuse txn object from the first allocation
        txn.begin()

        kvs2.put(b"k3", b"val3", txn=txn)
        kvs2.put(b"k4", b"val4", txn=txn)

        txn.abort()

        # Verify keys that are part of txn number 1 can be found
        val1 = kvs1.get(b"k1")
        print(f"txn1(committed), k1 from inside txn: found = {val1 is not None}")
        val2 = kvs1.get(b"k2")
        print(f"txn1(committed), k2 from outside txn: found = {val2 is not None}")

        # Verify keys that are part of txn number 2 cannot be found
        val3 = kvs1.get(b"k3")
        print(f"txn2(aborted), k3 from inside txn: found = {val3 is not None}")
        val4 = kvs1.get(b"k4")
        print(f"txn2(aborted), k4 from outside txn: found = {val4 is not None}")

    kvs1.close()
    kvs2.close()
    kvdb.close()

    return 0


if __name__ == "__main__":
    hse.init()
    try:
        main()
    finally:
        hse.fini()
