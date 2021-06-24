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

modules = [
    'hse',
    'limits',
    'experimental',
    'version',
]

pxds = []
foreach m : modules
    # HACK: cython needs pxds next to pyxs for whatever reasons and generators are dumb
    pxd = custom_target(
        '@0@-pxd'.format(m),
        build_by_default: true,
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

pyi_stubs = []
extension_modules = []
foreach m : modules
    pyi = custom_target(
        '@0@-pyi'.format(m),
        build_by_default: true,
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

    pyi_stubs += pyi

    pyx = custom_target(
        '@0@-pyx'.format(m),
        build_by_default: true,
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
        build_by_default: true,
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
        c,
        dependencies: [
            hse_dep,
            python.dependency(),
        ],
        subdir: 'hse',
        install: true,
    )

    extension_modules += extension_module
endforeach

python.install_sources(
    '__init__.py',
    'py.typed',
    subdir: 'hse',
    pure: false,
)
