#!/usr/bin/env python3

# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2022 Micron Technology, Inc. All rights reserved.

import errno
import sys

from hse3 import hse


def main() -> int:
    try:
        # None being passed as the KVDB home value is an error
        hse.Kvdb.open(None)  # type: ignore
    except hse.HseException as e:
        if e.returncode == errno.EINVAL:
            print(f"Correctly received a EINVAL for non-null argument: {str(e)}")
            return 0
        print(f"Unexpected errno value: {e.returncode}")
        return e.returncode

    return 0


if __name__ == "__main__":
    hse.init(
        None, "logging.destination=stdout", "logging.level=3", "socket.enabled=false"
    )
    try:
        sys.exit(main())
    finally:
        hse.fini()
