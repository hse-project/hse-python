import os
import pathlib
from typing import Any, Dict, List, Type
from setuptools import Command, find_packages, setup, Extension


HERE = pathlib.Path(__file__).parent
HSE_PACKAGE = HERE / "hse"


# Distribute the generated C source files so that consumers don't necessarily
# need Cython on their system to build the extensions.


USE_CYTHON = os.environ.get("USE_CYTHON")
SOURCE_EXTENSION = "pyx" if USE_CYTHON else "c"


extensions: List[Extension] = [
    Extension(
        "hse.hse",
        [str(HSE_PACKAGE / f"hse.{SOURCE_EXTENSION}")],
        libraries=["hse_kvdb"],
    ),
    Extension(
        "hse.limits",
        [str(HSE_PACKAGE / f"hse_limits.{SOURCE_EXTENSION}")],
        libraries=["hse_kvdb"],
    ),
    Extension(
        "hse.experimental",
        [str(HSE_PACKAGE / f"hse_experimental.{SOURCE_EXTENSION}")],
        libraries=["hse_kvdb"],
    ),
]


cmdclass: Dict[str, Type[Command]] = {}


if USE_CYTHON:
    from Cython.Build import cythonize
    from Cython.Compiler import Options
    from Cython.Distutils import build_ext

    # Help tools like Valgrind out
    Options.generate_cleanup_code = True
    Options.default_options["compile_time_env"] = {
        "HSE_PYTHON_DEBUG": 1 if os.environ.get("HSE_PYTHON_DEBUG") != None else 0,
    }

    def docstring_cythonize(modules: List[Extension]) -> List[Any]:
        if USE_CYTHON:
            import docstrings

            docstrings.insert(str(HSE_PACKAGE / "hse.in.pyx"))
            docstrings.insert(str(HSE_PACKAGE / "hse.in.pyi"))
            docstrings.insert(str(HSE_PACKAGE / "hse_limits.in.pyx"))
            docstrings.insert(str(HSE_PACKAGE / "limits.in.pyi"))
            docstrings.insert(str(HSE_PACKAGE / "hse_experimental.in.pyx"))
            docstrings.insert(str(HSE_PACKAGE / "experimental.in.pyi"))

        return cythonize(
            modules,
            annotate=True,
            include_path=["hse"],
            compiler_directives={
                "boundscheck": False,
                "wraparound": False,
                "nonecheck": False,
                "language_level": "3str",
                "embedsignature": True,
                "initializedcheck": False,
                "annotation_typing": True,
                "emit_code_comments": True,
                "optimize.use_switch": True,
                "optimize.unpack_method_calls": True,
                "warn.unreachable": True,
                "warn.maybe_uninitialized": True,
                "warn.multiple_declarators": True,
            },
        )

    extensions = docstring_cythonize(extensions)
    cmdclass["build_ext"] = build_ext


setup(
    name="hse",
    version="1.9",
    maintainer="Micron Technology, Inc.",
    description="Python bindings to HSE's C API. "
    "HSE is an embeddable key-value store designed for SSDs based on NAND "
    "flash or persistent memory. HSE optimizes performance and endurance by "
    "orchestrating data placement across DRAM and multiple classes of SSDs "
    "or other solid-state storage. HSE is ideal for powering NoSQL, "
    "Software-Defined Storage (SDS), High-Performance Computing (HPC), "
    "Big Data, Internet of Things (IoT), and Artificial Intelligence (AI) "
    "solutions.",
    long_description=(HERE / "README.md").read_text(),
    long_description_content_type="text/markdown",
    license="Apache-2.0",
    url="https://github.com/hse-project/hse-python",
    ext_modules=extensions,
    packages=find_packages(),
    cmdclass=cmdclass,
    package_data={"hse": ["*.pyi", "py.typed"]},
    exclude_package_data={"hse": ["*.in.pyi"]},
    zip_safe=False,
    keywords=[
        "micron",
        "hse",
        "key",
        "value",
        "object",
        "store",
        "database",
        "heterogeneous",
        "memory",
        "storage",
        "engine",
    ],
    classifiers=[
        "Development Status :: 1 - Planning",
        "License :: OSI Approved :: Apache Software License",
        "Operating System :: POSIX :: Linux",
        "Programming Language :: Cython",
        "Programming Language :: Python :: 3 :: Only",
        "Topic :: Database",
        "Topic :: Database :: Database Engines/Servers",
        "Typing :: Typed",
    ],
    project_urls={
        "HSE": "https://github.com/hse-project/hse",
        "HSE Wiki": "https://github.com/hse-project/hse/wiki",
    },
)
