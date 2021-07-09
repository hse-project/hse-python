import errno
from typing import Generator
from hse2 import hse
import pytest
from _pytest.config.argparsing import Parser
from _pytest.config import Config
import pathlib


def pytest_addoption(parser: Parser) -> None:
    parser.addoption("-C", "--home", type=pathlib.Path, default=pathlib.Path.cwd())


@pytest.fixture(scope="package")
def home(pytestconfig: Config) -> Generator[pathlib.Path, None, None]:
    return pytestconfig.getoption("home") # type: ignore


@pytest.fixture(scope="package")
def kvdb(home: pathlib.Path) -> Generator[hse.Kvdb, None, None]:
    hse.init()

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
