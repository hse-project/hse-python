#!/usr/bin/env python3

# This script exists because Python/Cython tooling is absolutely horrible. In
# what world do 2 copies of the same docstring have to be kept in a pyx file
# and a pyi file for there to be support for __doc__ and language servers, et.
# al.
#
# PYTHON IS PAIN...


import re
import toml
import sys
import argparse
import pathlib
from typing import Any, Dict, List, MutableMapping, Tuple, cast
from io import StringIO


__DOCSTRING_PATTERN = re.compile(r"(\s*)@SUB@\s+([a-zA-Z0-9._]+__doc__)")
__INDENT = " " * 4  # 4 space indents in source files


def __flatten(
    d: MutableMapping[str, Any], parent_key: str = "", sep: str = "."
) -> Dict[str, str]:
    items: List[Tuple[str, str]] = []
    for k, v in d.items():
        new_key = parent_key + sep + k if parent_key else k
        if v and isinstance(v, MutableMapping):
            items.extend(
                __flatten(cast(MutableMapping[str, Any], v), new_key, sep=sep).items()
            )
        else:
            items.append((new_key, v))
    return dict(items)


def insert(input_file: pathlib.Path, output_file: pathlib.Path, docstrings_toml: pathlib.Path) -> None:
    """
    Insert docstrings into a file out of place. `file.py.in` will output to
    `file.py`. If the input file has an older modified time than the previously
    created output file, then `insert` is a no-op. If the `docstrings.toml` has
    a newer modified time than the output file, the docstring insertion will
    always occur.

    Example location of where text replacement would happen::

        # module.py
        class MyClass:
            '''
            @SUB@ module.MyClass.__doc__ # <- text replacement
            '''

            def func(self):
                '''
                @SUB@ module.MyClass.__doc__ # <- text replacement
                '''

    Args:

    input_file - Path to file to insert docstrings into
    output_file - TODO
    docstrings_toml - TODO
    """
    HSE_DOCSTRINGS = __flatten(toml.load(docstrings_toml))

    with open(input_file, "r") as input:
        output_lines: List[str] = []
        for line in input.readlines():
            match = __DOCSTRING_PATTERN.search(line)
            if match is None:
                output_lines.append(line)
                continue
            indents = int(len(match.group(1)) / 4)
            key = match.group(2)
            if key in HSE_DOCSTRINGS.keys():
                with StringIO(HSE_DOCSTRINGS[key].lstrip()) as docstring:
                    output_lines.extend(
                        map(
                            lambda s: __INDENT * indents + s if not s.isspace() else s,
                            docstring.readlines(),
                        )
                    )

        with open(output_file, "w") as output:
            for line in output_lines:
                output.write(line)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Insert docstrings into input files")
    parser.add_argument("-o", "--output", nargs=1, required=True, help="Output file")
    parser.add_argument(
        "-d",
        "--docstrings",
        nargs=1,
        required=True,
        type=pathlib.Path,
        help="Path to docstrings.toml file",
    )
    parser.add_argument(
        "-f", "--file", nargs=1, required=True, type=pathlib.Path, help="Files to manipulate"
    )
    ns = parser.parse_args(sys.argv[1:])

    output = ns.output[0]
    docstrings_toml = ns.docstrings[0]
    file = ns.file[0]

    insert(file, output, docstrings_toml)
