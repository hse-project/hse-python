import hse
import os


def test_get_set():
    p = hse.Params()

    p.set("kvs.pfx_len", "3")

    assert p.get("kvs.pfx_len") == "3"


def test_from_string():
    p = hse.Params()

    p.from_string("api_version: 1\nkvs:\n  pfx_len: 3")

    assert p.get("kvs.pfx_len") == "3"


def test_from_file():
    p = hse.Params()

    p.from_file(
        str(os.path.join(os.path.dirname(os.path.abspath(__file__)), "config.yaml"))
    )

    assert p.get("kvs.pfx_len") == "3"
