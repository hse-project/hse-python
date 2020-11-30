import os
from typing import Any, Dict, List, Type
from setuptools import Command, setup, Extension


# Distribute the generated C source files so that consumers don't necessarily
# need Cython on their system to build the extensions.


USE_CYTHON = os.environ.get("USE_CYTHON")
SOURCE_EXTENSION = "pyx" if USE_CYTHON else "c"

extensions: List[Extension] = [
    Extension(
        "hse.hse",
        [os.path.join("hse", f"hse.{SOURCE_EXTENSION}")],
        libraries=["hse_kvdb"],
    ),
    Extension(
        "hse.limits",
        [os.path.join("hse", f"hse_limits.{SOURCE_EXTENSION}")],
        libraries=["hse_kvdb"],
    ),
    Extension(
        "hse.experimental",
        [os.path.join("hse", f"hse_experimental.{SOURCE_EXTENSION}")],
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

    def docstring_cythonize(modules: List[Extension]) -> List[Any]:
        if USE_CYTHON:
            import docstrings

            docstrings.insert(os.path.join("hse", "hse.in.pyx"))
            docstrings.insert(os.path.join("hse", "hse.in.pyi"))
            docstrings.insert(os.path.join("hse", "hse_limits.in.pyx"))
            docstrings.insert(os.path.join("hse", "limits.in.pyi"))
            docstrings.insert(os.path.join("hse", "hse_experimental.in.pyx"))
            docstrings.insert(os.path.join("hse", "experimental.in.pyi"))

        return cythonize(
            modules,
            include_path=["hse"],
            compiler_directives={
                "boundscheck": False,
                "wraparound": False,
                "nonecheck": False,
                "language_level": "3str",
                "embedsignature": True,
                "initializedcheck": False,
                "profile": os.environ.get("HSE_PYTHON_PROFILE") != None,
                "annotation_typing": True,
                "emit_code_comments": True,
                "optimize.use_switch": True,
                "optimize.unpack_method_calls": True,
                "warn.unreachable": True,
                "warn.maybe_uninitialized": True,
                "warn.multiple_declarators": True,
                "linetrace": os.environ.get("HSE_PYTHON_COVERAGE") != None,
            },
        )

    extensions = docstring_cythonize(extensions)
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
    packages=["hse"],
    cmdclass=cmdclass,
    package_dir={
        "hse": "hse",
    },
    zip_safe=False,
    package_data={"hse": ["*.pyi", "py.typed"]},
    exclude_package_data={"hse": ["*.in.pyi"]},
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
)
