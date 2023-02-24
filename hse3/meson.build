# SPDX-License-Identifier: Apache-2.0 OR MIT
#
# SPDX-FileCopyrightText: Copyright 2020 Micron Technology, Inc.

fs.copyfile(
    '__init__.py',
    install: true,
    install_dir: python.get_install_dir(pure: false) / root_module
)

fs.copyfile(
    'py.typed',
    install: true,
    install_dir: python.get_install_dir(pure: false) / root_module,
)

cython_directives = [
    'boundscheck=false',
    'wraparound=false',
    'nonecheck=false',
    'language_level=3str',
    'embedsignature=true',
    'initializedcheck=false',
    'annotation_typing=true',
    'emit_code_comments=true',
    'optimize.use_switch=true',
    'optimize.unpack_method_calls=true',
    'warn.unreachable=true',
    'warn.maybe_uninitialized=true',
    'warn.multiple_declarators=true',
]

cython_compile_time_env = [
    'HSE_PYTHON_EXPERIMENTAL=@0@'.format(get_option('experimental').to_int()),
    'PATH_MAX=@0@'.format(cc.get_define('PATH_MAX', prefix: '#include <limits.h>')),
]

modules = [
    'hse',
    'limits',
    'version',
]

foreach m : modules
    # HACK: cython needs pxds next to pyxs for whatever reason
    fs.copyfile('@0@.pxd'.format(m))
endforeach

extension_modules = []
foreach m : modules
    pyi = custom_target(
        '@0@.pyi.pp'.format(m),
        input: meson.current_source_dir() / '@0@.in.pyi'.format(m),
        command: [
            pp,
            get_option('experimental') ? ['--experimental'] : [],
            '--file',
            '@INPUT@',
            '--output',
            '@OUTPUT@',
        ],
        output: '@0@.pyi.pp'.format(m)
    )

    pyi = custom_target(
        '@0@.pyi'.format(m),
        input: pyi,
        command: [
            docstrings,
            '--file',
            '@INPUT@',
            '--output',
            '@OUTPUT@',
        ],
        depend_files: [
            docstrings.full_path(),
        ],
        output: '@0@.pyi'.format(m),
        install: true,
        install_dir: python.get_install_dir(pure: false) / root_module
    )

    pyx = custom_target(
        '@0@.pyx'.format(m),
        input: meson.current_source_dir() / '@0@.in.pyx'.format(m),
        command: [
            docstrings,
            '--file',
            '@INPUT@',
            '--output',
            '@OUTPUT@',
        ],
        depend_files: [
            docstrings.full_path(),
        ],
        output: '@0@.pyx'.format(m)
    )

    extension_module = python.extension_module(
        '@0@'.format(m),
        pyx,
        pyi,
        cython_args: [
            '--directive=@0@'.format(','.join(cython_directives)),
            '--compile-time-env=@0@'.format(','.join(cython_compile_time_env)),
            '--include-dir',
            meson.current_build_dir(),
        ],
        dependencies: [
            hse_dep,
            python.dependency(),
        ],
        subdir: root_module,
        install: true
    )

    extension_modules += extension_module
endforeach
