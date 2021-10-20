# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2020-2021 Micron Technology, Inc. All rights reserved.

import os
import pathlib
from typing import Any, Dict, List, Type
from setuptools import Command, find_packages, setup, Extension


HERE = pathlib.Path(__file__).parent
HSE_PACKAGE = pathlib.Path("hse2")


# Distribute the generated C source files so that consumers don't necessarily
# need Cython on their system to build the extensions.


USE_CYTHON = bool(os.environ.get("USE_CYTHON", 0))
SOURCE_EXTENSION = "pyx" if USE_CYTHON else "c"
COMPILE_TIME_ENV = {
    "HSE_PYTHON_DEBUG": bool(os.environ.get("HSE_PYTHON_DEBUG", 0)),
    "HSE_PYTHON_EXPERIMENTAL": bool(os.environ.get("HSE_PYTHON_EXPERIMENTAL", 0)),
}

extensions: List[Extension] = [
    Extension(
        "hse2.hse",
        [str(HSE_PACKAGE / f"hse.{SOURCE_EXTENSION}")],
        libraries=["hse-2"],
    ),
    Extension(
        "hse2.limits",
        [str(HSE_PACKAGE / f"limits.{SOURCE_EXTENSION}")],
        libraries=["hse-2"],
    ),
    Extension(
        "hse2.version",
        [str(HSE_PACKAGE / f"version.{SOURCE_EXTENSION}")],
        libraries=["hse-2"],
    ),
]


cmdclass: Dict[str, Type[Command]] = {}


if USE_CYTHON:
    from Cython.Build import cythonize
    from Cython.Compiler import Options
    from Cython.Distutils import build_ext

    # Help tools like Valgrind out
    Options.generate_cleanup_code = True

    def precythonize(modules: List[Extension]) -> List[Any]:
        import docstrings
        import pp

        pp.preprocess(
            HSE_PACKAGE / "hse.in.pyi",
            HSE_PACKAGE / "hse.pyi.pp",
            COMPILE_TIME_ENV["HSE_PYTHON_EXPERIMENTAL"],
        )

        docstrings.insert(
            HSE_PACKAGE / "hse.in.pyx",
            HSE_PACKAGE / "hse.pyx",
            HERE / "docstrings.toml",
        )
        docstrings.insert(
            HSE_PACKAGE / "hse.pyi.pp",
            HSE_PACKAGE / "hse.pyi",
            HERE / "docstrings.toml",
        )
        docstrings.insert(
            HSE_PACKAGE / "limits.in.pyx",
            HSE_PACKAGE / "limits.pyx",
            HERE / "docstrings.toml",
        )
        docstrings.insert(
            HSE_PACKAGE / "limits.in.pyi",
            HSE_PACKAGE / "limits.pyi",
            HERE / "docstrings.toml",
        )
        docstrings.insert(
            HSE_PACKAGE / "version.in.pyx",
            HSE_PACKAGE / "version.pyx",
            HERE / "docstrings.toml",
        )
        docstrings.insert(
            HSE_PACKAGE / "version.in.pyi",
            HSE_PACKAGE / "version.pyi",
            HERE / "docstrings.toml",
        )

        return cythonize(
            modules,
            include_path=["hse2"],
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
            compile_time_env=COMPILE_TIME_ENV,
            verbose=True,
        )

    extensions = precythonize(extensions)
    cmdclass["build_ext"] = build_ext


setup(
    name="hse2",
    version="2.0.1",
    maintainer="Micron HSE",
    maintainer_email="hse@micron.com",
    description="HSE is a fast embeddable key-value store designed for SSDs and persistent memory.",
    long_description=(HERE / "README.md").read_text(),
    long_description_content_type="text/markdown",
    license="Apache-2.0",
    url="https://github.com/hse-project/hse-python",
    ext_modules=extensions,
    packages=find_packages(),
    cmdclass=cmdclass,
    package_data={"hse2": ["*.pyi", "py.typed"]},
    include_package_data=True,
    exclude_package_data={"hse2": ["*.in.pyi", "*.pp"]},
    zip_safe=False,
    keywords=[
        "micron",
        "hse",
        "key",
        "value",
        "database",
        "bindings",
        "heterogeneous",
        "memory",
        "storage",
        "engine",
    ],
    classifiers=[
        "License :: OSI Approved :: Apache Software License",
        "Operating System :: POSIX :: Linux",
        "Programming Language :: Cython",
        "Programming Language :: Python :: 3 :: Only",
        "Topic :: Database",
        "Topic :: Database :: Database Engines/Servers",
        "Typing :: Typed",
    ],
    project_urls={
        "repohome": "https://github.com/hse-project/hse-python",
        "projecthome": "https://hse-project.github.io",
    },
)
