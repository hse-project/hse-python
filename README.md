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

### Working the HSE Repository

If you are working on a feature or bug that requires work in both `hse` and
`hse-python`, then make `subprojects/hse` a symlink to the `hse` repository on
your system. Then in the event you edit `hse`, `hse-python` will see the
changes as well and re-build/re-link appropriately.

## Testing

Export the `PYTHONPATH` environment variable to the root of this repository.
From there you should be able to run `pytest` without error.

You can skip the export of the environment variable by running
`python -m pytest` instead.

In the case you need to tell Python where the HSE library is, you can use
the `LD_LIBRARY_PATH` environment variable.

```shell
export PYTHONPATH=.
# export LD_LIBRARY_PATH=path/to/library:$LD_LIBRARY_PATH
pytest
# or
python -m pytest
```

## Contributing

Please format Python source and stub files with
[`black`](https://github.com/psf/black).

If you are contributing to the project, you should define a `USE_CYTHON`
environment variable. The value is irrelevant as long as it is defined.

Cython source files, docstrings, and stub files do not seem to mesh well
together. In order to get `__doc__` attributes in Python and documentation on
hover in various editors and IDEs, docstrings need to be in the Cython source
and the stub files. Because of this unfortunate fact, docstrings are kept out
of source files and in `docstrings.toml`. The `docstrings.py` script will
perform text insertion based on keys in the TOML file when processing the
Cython source and stub files. That means in order to get a build of
`hse-python` with docstrings, you will need to run `docstrings.py` on any
`pyi.in` and `pyx.in` files in this repository. This has been seemlessly
added to the `build_ext` process, so it should insert docstrings
automagically when `USE_CYTHON` is defined.

When finishing up contributions to the project, make sure your changes
compile with `-Werror`.

In order to contribute to the project, you may want to setup a virtual
environment for the project which can be done using the following:

```shell
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```
