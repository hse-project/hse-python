#!/usr/bin/env python3

from hse.hse import Kvs, Params
from hse import Kvdb
import struct
import argparse
import threading


def put_keys(kvs: Kvs, start: int, end: int):
    for i in range(start, end):
        key = struct.pack(">L", i)
        val = struct.pack(">LL", i, i)
        kvs.put(key, val)


def parse_cmdline():
    desc = "Put binary keys\n\n" "example: %(prog)s mp1 kvs1 -c1000\n"
    p = argparse.ArgumentParser(
        description=desc, formatter_class=argparse.RawTextHelpFormatter
    )
    p.add_argument("-c", "--count", type=int, help="Number of keys", required=True)
    p.add_argument(
        "-t", "--threads", type=int, help="Number of threads", required=False
    )

    # Positional Arguments
    p.add_argument("mpool", help="mpool name")
    p.add_argument("kvs", help="kvs name")
    return p.parse_args()


def main() -> int:
    opts = parse_cmdline()

    Kvdb.init()

    p = Params()
    p.set("kvdb.throttle_disable", "1")

    kvdb = Kvdb.open(opts.mpool, params=p)
    kvs = kvdb.kvs_open(opts.kvs)

    nthread = opts.threads
    if nthread == None:
        nthread = 1

    thread_list = []
    stride = int(opts.count / nthread)
    for i in range(0, nthread):
        start = i * stride
        s = stride
        if i == nthread - 1:
            s = stride + int(opts.count % nthread)
        end = start + s
        th = threading.Thread(
            target=put_keys, kwargs={"kvs": kvs, "start": int(start), "end": int(end)}
        )
        thread_list.append(th)
        th.start()

    for t in thread_list:
        t.join()

    kvdb.close()
    Kvdb.fini()

    return 0


if __name__ == "__main__":
    main()
