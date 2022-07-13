# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2021-2022 Micron Technology, Inc. All rights reserved.

import argparse
import errno
import pathlib
import sys
import unittest
from typing import Iterable, List, Tuple, cast

from hse3 import hse


class TestArgs:
    home: pathlib.Path
    config: pathlib.Path
    experimental: bool


__parser = argparse.ArgumentParser()

__parser.add_argument("-C", "--home", type=pathlib.Path, default=pathlib.Path.cwd())
__parser.add_argument("--config", type=pathlib.Path)
__parser.add_argument("--experimental", action="store_true")

ARGS, __unknown = cast(Tuple['TestArgs', List[str]], __parser.parse_known_args())
UNKNOWN = [sys.argv[0], *__unknown]


class HseTestCase(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        hse.init(ARGS.config, "socket.enabled=false")

    @classmethod
    def tearDownClass(cls) -> None:
        hse.fini()


def kvdb_fixture(
    home: pathlib.Path = ARGS.home,
    cparams: Iterable[str] = (),
    rparams: Iterable[str] = (),
) -> hse.Kvdb:
    try:
        hse.Kvdb.create(home, *cparams)
    except hse.HseException as e:
        if e.returncode != errno.EEXIST:
            raise e
    return hse.Kvdb.open(home, *rparams)


def kvs_fixture(
    kvdb: hse.Kvdb,
    name: str,
    cparams: Iterable[str] = (),
    rparams: Iterable[str] = (),
) -> hse.Kvs:
    try:
        kvdb.kvs_create(name, *cparams)
    except hse.HseException as e:
        if e.returncode != errno.EEXIST:
            raise e
    return kvdb.kvs_open(name, *rparams)
