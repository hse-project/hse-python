project(
    'hse-python',
    ['c'], # until Meson supports Cython as a language
    version: '2.0.0',
    default_options: [
        'prefix=/opt/hse',
        'buildtype=debugoptimized',
        'warning_level=2',
        # Meson for whatever reason chooses not to respect HSE's default
        # options :).
        'force_fallback_for=xxhash,lz4,cjson',
    ],
    meson_version: '>=0.57',
)

sh = find_program('sh')

ci = run_command(sh, '-c', '[ ${CI+x} ]', check: false).returncode() == 0

version_components = meson.project_version().split('.')

hse_python_major_version = version_components[0]
hse_python_minor_version = version_components[1]
hse_python_patch_version = version_components[2]

hse_python_module_name = 'hse@0@'.format(hse_python_major_version)

cc = meson.get_compiler('c')

fs = import('fs')
pymod = import('python')

docstrings = find_program('docstrings.py')
pp = find_program('pp.py')
cython = find_program('cython')
python = pymod.find_installation('python3')

if not meson.is_subproject()
    black = find_program('black', required: ci)
    if black.found()
        black_command = [
            black,
            meson.project_source_root(),
        ]

        run_target(
            'format',
            command: black_command
        )

        run_target(
            'format-check',
            command: [
                black_command,
                '--check',
                '--diff',
            ]
        )
    endif
endif

# Exported for usage in hse.
project_build_root = meson.project_build_root()

hse_dep = dependency(
    'hse-2',
    version: '>=2.1.0',
    required: true,
    fallback: ['hse', 'hse_dep'],
    default_options: [
        'cli=false',
        'docs=disabled',
        'tests=false',
        'tools=disabled',
        'samples=false',
        'bindings=none',
        'db_bench=false',
    ],
)

subdir('hse2')

if get_option('tests')
    subdir('tests')
endif

run_target(
    'python-repl',
    command: [
        python,
    ],
    env: environment({
        'PYTHONPATH': '@0@:@1@'.format(meson.project_build_root(), meson.project_source_root()),
    }),
    depends: [
        extension_modules,
    ]
)
