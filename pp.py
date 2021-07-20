#!/usr/bin/env python3

import argparse
import pathlib
import sys


def preprocess(file: pathlib.Path, output: pathlib.Path, experimental: bool):
    lines = file.read_text().splitlines(keepends=True)
    with open(output, "w") as out:
        while lines:
            line = lines.pop(0)
            if line.strip() == "#ifdef HSE_PYTHON_EXPERIMENTAL":
                line = lines.pop(0)
                while line.strip() != "#endif":
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
