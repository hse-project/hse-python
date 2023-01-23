#!/usr/bin/env python3

# SPDX-License-Identifier: Apache-2.0 OR MIT
#
# SPDX-FileCopyrightText: Copyright 2020 Micron Technology, Inc.

import sys

from hse3 import hse


def main():
    home = sys.argv[1]

    kvdb = hse.Kvdb.open(home, "mode=rdonly")

    kvdb.close()


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <kvdb_home>", file=sys.stderr)
        sys.exit(1)

    hse.init(
        None, "logging.destination=stdout", "logging.level=3", "rest.enabled=false"
    )
    try:
        main()
    finally:
        hse.fini()
