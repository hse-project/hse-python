import os
import pathlib
from setuptools import setup, Extension


# Distribute the generated C source files so that consumers don't necessarily
# need Cython on their system to build the extensions.


USE_CYTHON = os.environ.get("USE_CYTHON")
PROJECT_PATH = pathlib.Path(os.path.dirname(os.path.realpath(__file__)))

extensions = [
    Extension(
        "hse.hse",
        [str(PROJECT_PATH.joinpath("hse", f"hse.{'pyx' if USE_CYTHON else 'c'}"))],
        libraries=["hse_kvdb"],
    ),
    Extension(
        "hse.limits",
        [
            str(
                PROJECT_PATH.joinpath(
                    "hse", f"hse_limits.{'pyx' if USE_CYTHON else 'c'}"
                )
            )
        ],
        libraries=["hse_kvdb"],
    ),
]


cmdclass = {}


if USE_CYTHON:
    from Cython.Build import cythonize
    from Cython.Distutils import build_ext

    extensions = cythonize(extensions, include_path=["."])
    cmdclass["build_ext"] = build_ext


setup(
    name="hse",
    version="1.9",
    maintainer="Micron Technology",
    description="Python bindings to HSE's C API. "
    "HSE is an embeddable key-value store designed for SSDs based on NAND "
    "flash or persistent memory. HSE optimizes performance and endurance by "
    "orchestrating data placement across DRAM and multiple classes of SSDs "
    "or other solid-state storage. HSE is ideal for powering NoSQL, "
    "Software-Defined Storage (SDS), High-Performance Computing (HPC), "
    "Big Data, Internet of Things (IoT), and Artificial Intelligence (AI) "
    "solutions.",
    license="Apache-2.0",
    url="https://github.com/hse-project",
    ext_modules=extensions,
    packages=["hse", "hse.limits"],
    cmdclass=cmdclass,
    package_dir={
        "hse": str(PROJECT_PATH.joinpath("hse")),
        "hse.limits": str(PROJECT_PATH.joinpath("hse")),
    },
    package_data={"hse": ["*.pyi", "py.typed"]},
    keywords="micron hse key value object store",
)
