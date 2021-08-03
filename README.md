# HSE Python Bindings

[Heterogeneous-Memory Storage Engine](https://github.com/hse-project/hse)
bindings for Python.

## Dependencies

Dependencies that are bolded are runtime dependencies. **HSE** is both a
runtime and build dependency.

* **HSE**, cloned locally and built, or installed on your system including the
development package
* [`Cython`](https://pypi.org/project/Cython) (optional unless `USE_CYTHON` is defined)
* [`toml`](https://pypi.org/project/toml/) (optional unless `USE_CYTHON` is
defined)
* [`pytest`](https://pypi.org/project/pytest)
* [`black`](https://pypi.org/project/black)

## Installation

### From PyPI

```shell
# unpublished as of now
pip install hse
```

### From Build

```shell
python setup.py install
```

## Building

If you need to point the build toward the HSE include directory or the shared
library, you can use `CFLAGS` and `LDFLAGS` respectively.

In the case you are bootstrapping your build, such as from a fresh clone, you
will want to define an environment variable called `USE_CYTHON`. What it is
defined as is unimportant. If you are building from a source distribution, then
`USE_CYTHON` is unimportant. The Cython generated `.c` files are distributed in
the source distribution. This is off by default.

If you are interested in more contextual error messages that the C API is
bubbling up, then you can define the environment variable `HSE_PYTHON_DEBUG`.
This will provide the C file and line number where the error originated. This is
off by default.

```shell
python setup.py build_ext -i
# or
CFLAGS="-Ipath/to/include" LDFLAGS="-Lpath/to/search" python setup.py build_ext -i
```

