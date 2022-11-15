# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2021-2022 Micron Technology, Inc. All rights reserved.

import argparse
import atexit
import errno
import os
import pathlib
import shutil
import signal
import sys
import tempfile
import unittest
from types import FrameType
from typing import Iterable, List, Tuple, Optional, cast, TYPE_CHECKING

from hse3 import hse

if TYPE_CHECKING:

    class TestArgs:
        home: pathlib.Path
        config: pathlib.Path
        experimental: bool


def __default_dir() -> str:
    directory = tempfile.gettempdir()
    for d in [
        os.getenv("HSE_TEST_RUNNER_DIR"),
        os.getenv("MESON_BUILD_ROOT"),
    ]:
        if d:
            directory = d
            break

    tmpdir = tempfile.TemporaryDirectory(
        prefix=f"mtest-{pathlib.Path(sys.argv[0]).name}-", dir=directory
    )

    def __cleanup(sig: int, frame: Optional[FrameType]) -> None:
        shutil.rmtree(tmpdir.name)

    atexit.register(shutil.rmtree, tmpdir.name)
    for s in set(signal.Signals) - {signal.SIGKILL, signal.SIGSTOP, signal.SIGCHLD}:
        signal.signal(s, __cleanup)

    return tmpdir.name


__parser = argparse.ArgumentParser()

__parser.add_argument(
    "-C", "--home", type=pathlib.Path, default=pathlib.Path(__default_dir())
)
__parser.add_argument("--config", type=pathlib.Path)
__parser.add_argument("--experimental", action="store_true")

ARGS, __unknown = cast(Tuple["TestArgs", List[str]], __parser.parse_known_args())
UNKNOWN = [sys.argv[0], *__unknown]


class HseTestCase(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        hse.init(ARGS.config, "rest.enabled=false")

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
