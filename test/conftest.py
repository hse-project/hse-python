import errno
from typing import Generator
import hse
import pytest


@pytest.fixture(scope="package")
def kvdb() -> Generator[hse.Kvdb, None, None]:
    hse.Kvdb.init()

    try:
        hse.Kvdb.make("hse-python-test")
    except hse.KvdbException as e:
        if e.returncode == errno.EEXIST:
            pass
        else:
            raise e

    kvdb = hse.Kvdb.open("hse-python-test")

    yield kvdb

    hse.Kvdb.fini()
