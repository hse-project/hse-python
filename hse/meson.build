compiler_directives = [
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

compile_time_env = [
    'HSE_PYTHON_DEBUG=@0@'.format(
        get_option('buildtype').startswith('debug') ? 1 : 0
    ),
]

extra_cython_args = []

if get_option('werror')
    extra_cython_args += '-Werror'
endif

init_py = custom_target(
    '__init__.py',
    input: '__init__.py',
    output: '__init__.py',
    command: [
        'cp',
        '@INPUT@',
        '@OUTPUT@',
    ],
    install: true,
    install_dir: python.get_install_dir(pure: false) / 'hse',
)

py_typed = custom_target(
    'py.typed',
    input: 'py.typed',
    output: 'py.typed',
    command: [
        'cp',
        '@INPUT@',
        '@OUTPUT@',
    ],
    install: true,
    install_dir: python.get_install_dir(pure: false) / 'hse',
)

modules = [
    'hse',
    'limits',
    'version',
]

pxds = []
foreach m : modules
    # HACK: cython needs pxds next to pyxs for whatever reasons and generators are dumb
    pxd = custom_target(
        '@0@-pxd'.format(m),
        input: '@0@.pxd'.format(m),
        command: [
            'cp',
            '@INPUT@',
            '@OUTPUT@',
        ],
        output: '@0@.pxd'.format(m),
    )

    pxds += pxd
endforeach

extension_modules = []
foreach m : modules
    pyi = custom_target(
        '@0@-pyi'.format(m),
        input: meson.current_source_dir() / '@0@.in.pyi'.format(m),
        command: [
            docstrings,
            '--file',
            '@INPUT@',
            '--output',
            '@OUTPUT@',
            '--docstrings',
            meson.project_source_root() / 'docstrings.toml',
        ],
        depend_files: [
            docstrings.full_path(),
            meson.project_source_root() / 'docstrings.toml',
        ],
        output: '@0@.pyi'.format(m),
        install: true,
        install_dir: python.get_install_dir(pure: false) / 'hse'
    )

    pyx = custom_target(
        '@0@-pyx'.format(m),
        input: meson.current_source_dir() / '@0@.in.pyx'.format(m),
        command: [
            docstrings,
            '--file',
            '@INPUT@',
            '--output',
            '@OUTPUT@',
            '--docstrings',
            meson.project_source_root() / 'docstrings.toml',
        ],
        depend_files: [
            docstrings.full_path(),
            meson.project_source_root() / 'docstrings.toml',
        ],
        output: '@0@.pyx'.format(m),
    )

    c = custom_target(
        '@0@-c'.format(m),
        input: pyx,
        command: [
            cython,
            '@INPUT@',
            '--output-file',
            '@OUTPUT@',
            '--directive',
            ','.join(compiler_directives),
            '--compile-time-env',
            ','.join(compile_time_env),
            '--include-dir',
            meson.current_build_dir(),
            extra_cython_args,
        ],
        output: '@0@.c'.format(m),
        depends: [
            pxds,
        ],
    )

    extension_module = python.extension_module(
        '@0@'.format(m),
        [c, init_py, py_typed, pyi],
        c_args: [
            '-DHSE_EXPERIMENTAL',
        ],
        dependencies: [
            hse_dep,
            python.dependency(),
        ],
        subdir: 'hse',
        install: true,
    )

    extension_modules += extension_module
endforeach
