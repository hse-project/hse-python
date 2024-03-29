<!--
SPDX-License-Identifier: Apache-2.0 OR MIT

SPDX-FileCopyrightText: Copyright 2020 Micron Technology, Inc.
-->

# HSE Python Bindings

[Heterogeneous-Memory Storage Engine](https://github.com/hse-project/hse)
bindings for Python.

## Building

### Dependencies

- `Cython >= 0.29.21` (install from system repositories or PyPI)

---

`hse-python` is built using the [Meson build system](https://mesonbuild.com/).
In the event HSE is not visible to the `hse-python` build system, HSE will be
fetched and built alongside `hse-python`.

```shell
meson setup build
meson compile -C build
```

Check the output of `meson configure build` or
[`meson_options.txt`](./meson_options.txt) for various build options.

## Installation

### From PyPI

```shell
python3 -m pip install hse
```

In this case, you may need to properly set `CFLAGS` and `LDFLAGS` according to
your environment, since hse-python will have to be compiled from source behind
the scenes.

### From Build

The default install directory is `/opt/hse`[^1]. This can be overridden by
configuring the build with either `-Dprefix=$prefix` or `--prefix=$prefix`.

```shell
meson install -C build
```

## Additional References

Information on running test suites and contributing to `hse-python` is located
in the [`CONTRIBUTING.md`](./CONTRIBUTING.md) file.

[^1]: You may have to configure your `PYTHONPATH` environment variable to allow
the Python interpreter to see the `hse-python` module. This is almost surely
the case if you do not change the default install prefix.
