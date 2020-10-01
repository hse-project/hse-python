#!/usr/bin/env python3

from typing import List
import hse
from hse import limits
import sys
import argparse
from functools import partial


# This example demonstrates how one could add key-value pairs where the value
# length could be larger than the allowed maximum hse.KVS_VLEN_MAX.
#
# To put keys, this example uses files passed to it on the commandline. Each
# file's name forms the prefix of a key and its contents are chunked into the
# values. For instance, if one were to put /tmp/foo and /tmp/bar into kvs1 in
# mpool mp1, the commandline would read:
#
#            ex5_large_val.py mp1 kvs1 /tmp/foo /tmp/bar
#
# This would put the keys:
#
#     /tmp/foo00000000
#     /tmp/foo00000001
#     /tmp/foo00000002
#     ...
#     /tmp/foo00000NNN
#
# for chunks of size hse.KVS_VLEN_MAX read from /tmp/foo. Similarly, the file
# /tmp/bar will be split into multiple chunks starting with keys starting at
# /tmp/bar00000000
#
# To extract the key-value pairs, use the option '-x' on the commandline. For
# the example above, the commandline will look like this:
#
#            ex5_large_val.py mp1 kvs1 -x /tmp/foo /tmp/bar
#
# And the values for each key/file will be output into '/tmp/foo.out' and
# '/tmp/bar.out' respectively.
#
# NOTE - the names of the files given in the extract run must exactly match
# the file names inserted or the data will not be found.


def extract_kv_to_files(kvs: hse.Kvs, files: List[str]) -> None:
    for file in files:
        outfile = file + ".out"
        print(f"filename: {outfile}")
        with open(outfile, "rb+") as f:
            cursor = kvs.cursor_create(f"{file}|".encode())
            for _, chunk in cursor.items():
                if chunk:
                    f.write(chunk)
            cursor.destroy()


def put_files_as_kv(kvs: hse.Kvs, keys: List[str]) -> None:
    for key in keys:
        with open(key, "rb") as f:
            for i, chunk in enumerate(iter(partial(f.read, limits.KVS_VLEN_MAX), b"")):
                kvs.put(f"{key}|{i:08x}".encode(), chunk)


def main() -> int:
    parser = argparse.ArgumentParser(
        usage=f"{sys.argv[0]} <kvdb> <kvs> <file1> [<fileN> ...]", add_help=True
    )
    parser.add_argument("kvdb", help="kvdb to operate in")
    parser.add_argument("kvs", help="kvs to operate in")
    parser.add_argument("files", nargs="+", help="files to operate on")
    parser.add_argument("-x", action="store_true")
    args = parser.parse_args(sys.argv[1:])

    MPOOL_NAME: str = args.kvdb
    KVS_NAME: str = args.kvs
    FILES: List[str] = args.files

    hse.Kvdb.init()

    kvdb = hse.Kvdb.open(MPOOL_NAME)
    kvs = kvdb.kvs_open(KVS_NAME)

    if args.x:
        extract_kv_to_files(kvs, FILES)
    else:
        put_files_as_kv(kvs, FILES)

    kvdb.close()

    hse.Kvdb.fini()

    return 0


if __name__ == "__main__":
    sys.exit(main())
