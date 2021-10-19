#!/usr/bin/env python3

# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2020-2021 Micron Technology, Inc. All rights reserved.

import argparse
import pathlib
import re
import sys


IFDEF_RE = re.compile(r"#\W+ifdef\W+HSE_PYTHON_EXPERIMENTAL")
ENDIF_RE = re.compile(r"#\W+endif")


def preprocess(file: pathlib.Path, output: pathlib.Path, experimental: bool = False):
    lines = file.read_text().splitlines(keepends=True)
    with open(output, "w") as out:
        while lines:
            line = lines.pop(0)
            if IFDEF_RE.match(line.strip()):
                line = lines.pop(0)
                while ENDIF_RE.match(line.strip()):
                    if experimental:
                        out.write(line)
                    else:
                        pass
                    line = lines.pop(0)
            else:
                out.write(line)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Insert docstrings into input files")
    parser.add_argument(
        "-o", "--output", type=pathlib.Path, nargs=1, required=True, help="Output file"
    )
    parser.add_argument(
        "-f",
        "--file",
        type=pathlib.Path,
        nargs=1,
        required=True,
        help="Files to manipulate",
    )
    parser.add_argument(
        "--experimental", action="store_true", help="Enable experimental"
    )
    ns = parser.parse_args(sys.argv[1:])

    file = ns.file[0]
    output = ns.output[0]
    experimental = ns.experimental

    preprocess(file, output, experimental)
