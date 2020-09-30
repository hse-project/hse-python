# HSE Python Bindings

[Heterogeneous-Memory Storage Engine](https://github.com/hse-project/hse)
bindings for Python.

## Dependencies

* Cython (optional if building from source distributions such as release tarballs)
* HSE, cloned locally and built, or installed on your system including the
development package

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

If you need to point Cython toward the HSE include directory or the shared
library, you can use `CFLAGS` and `LDFLAGS` respectively.

```shell
python setup.py build_ext -i
# or
CFLAGS="-Ipath/to/include" LDFLAGS="-Lpath/to/search" python setup.py build_ext -i
```

## Testing

Export the `PYTHONPATH` environment variable to the root of this repository.
From there you should be able to run `python -c "import hse"` without error.

In the case you need to tell Python where the HSE library is, you can use
the `LD_LIBRARY_PATH` environment variable.

```shell
export PYTHONPATH=.
# export LD_LIBRARY_PATH=path/to/library:$LD_LIBRARY_PATH
python -c "import hse"
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
