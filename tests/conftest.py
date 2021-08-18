# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2020-2021 Micron Technology, Inc. All rights reserved.

import errno
from typing import Generator, List
from hse2 import hse
import pytest
from _pytest.config.argparsing import Parser
from _pytest.config import Config
from _pytest.python import Function
import pathlib


def pytest_addoption(parser: Parser) -> None:
    parser.addoption("-C", "--home", type=pathlib.Path, default=pathlib.Path.cwd())
    parser.addoption("--experimental", action="store_true")


def pytest_collection_modifyitems(config: Config, items: List[Function]):
    if config.getoption("--experimental"): # type: ignore
        return
    experimental = pytest.mark.skip(reason="need --experimental option to run")
    for item in items:
        if "experimental" in item.keywords: # type: ignore
            item.add_marker(experimental)


@pytest.fixture(scope="package")
def home(pytestconfig: Config) -> Generator[pathlib.Path, None, None]:
    return pytestconfig.getoption("home") # type: ignore


@pytest.fixture(scope="package")
def kvdb(home: pathlib.Path) -> Generator[hse.Kvdb, None, None]:
    hse.init(home)

    try:
        hse.Kvdb.create(home)
    except hse.HseException as e:
        if e.returncode == errno.EEXIST:
            pass
        else:
            raise e

    kvdb = hse.Kvdb.open(home)

    yield kvdb

    kvdb.close()
    hse.Kvdb.drop(home)
    hse.fini()
