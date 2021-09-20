#!/usr/bin/env python3

# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2021 Micron Technology, Inc. All rights reserved.

import sys

from hse2 import hse


def main():
    home = sys.argv[1]

    kvdb = hse.Kvdb.open(home, "read_only=true")

    kvdb.close()


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <kvdb_home>", file=sys.stderr)
        sys.exit(1)

    hse.init(
        None, "logging.destination=stdout", "logging.level=3", "socket.enabled=false"
    )
    try:
        main()
    finally:
        hse.fini()
