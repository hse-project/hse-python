#!/usr/bin/env python

# This script exists because Python/Cython tooling is absolutely horrible. In
# what world do 2 copies of the same docstring have to be kept in a pyx file
# and a pyi file for there to be support for __doc__ and language servers, et.
# al.
#
# PYTHON IS PAIN...


import re
import toml
import sys
import os
from typing import Any, Dict, MutableMapping, cast
from io import StringIO


__DOCSTRING_PATTERN = re.compile(r"(\s*)@SUB@\s+([a-zA-Z0-9._]+__doc__)")
__INDENT = " " * 4  # 4 space indents in source files


def __flatten(
    d: MutableMapping[str, Any], parent_key: str = "", sep: str = "."
) -> Dict[str, Any]:
    items = []
    for k, v in d.items():
        new_key = parent_key + sep + k if parent_key else k
        if v and isinstance(v, MutableMapping):
            items.extend(
                __flatten(cast(MutableMapping[str, Any], v), new_key, sep=sep).items()
            )
        else:
            items.append((new_key, v))
    return dict(items)


__HSE_DOCSTRINGS = __flatten(toml.load("docstrings.toml"))
__DOCSTRINGS_TOML_MDATE = os.path.getmtime("docstrings.toml")


def insert(file: str) -> None:
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

    file - Path to file to insert docstrings into
    """
    assert file.find(".in.") != -1

    input_file_mtime = os.path.getmtime(file)
    output_file = file.replace(".in", "")
    if os.path.exists(output_file):
        output_file_mtime = os.path.getmtime(output_file)
        if (
            input_file_mtime < output_file_mtime
            and __DOCSTRINGS_TOML_MDATE < output_file_mtime
        ):
            return

    with open(file, "r") as input:
        output_lines = []
        for line in input.readlines():
            match = __DOCSTRING_PATTERN.search(line)
            if match is None:
                output_lines.append(line)
                continue
            indents = int(len(match.group(1)) / 4)
            key = match.group(2)
            if key in __HSE_DOCSTRINGS.keys():
                with StringIO(__HSE_DOCSTRINGS[key]) as docstring:
                    output_lines.extend(
                        map(
                            lambda s: __INDENT * indents + s if not s.isspace() else s,
                            docstring.readlines(),
                        )
                    )

        # Remove the .in suffix
        with open(output_file, "w") as output:
            for line in output_lines:
                output.write(line)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <file1> [<file2>...<fileN>]")
        sys.exit(1)

    for file in sys.argv[1:]:
        insert(sys.argv[1])
