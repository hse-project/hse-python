# HSE Python Bindings

[Heterogeneous-Memory Storage Engine](https://github.com/hse-project/hse)
bindings for Python.

## Virtual Environment

To build `hse-python`, it may be advantageous to use a Python virtual
environment. Use the following commands to set one up:

```shell
python3 -m venv venv
source venv/bin/activate
python3 -m pip install -r requirements.txt
```

## Building

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
python3 -m pip install hse2
```

### From Build

The default install directory is `/opt/hse`. This can be overridden by
configuring the build with either `-Dprefix=$prefix` or `--prefix=$prefix`.

```shell
meson install -C build
```

## Additional References

Information on running test suites and contributing to `hse-python` is located
in the [`CONTRIBUTING.md`](./CONTRIBUTING.md) file.
