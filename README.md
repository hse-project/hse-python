# HSE Python Bindings

[Heterogeneous-Memory Storage Engine](https://github.com/hse-project/hse)
bindings for Python.

## Dependencies

* Cython (optional, if building from source distributions such as release tarballs)
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
