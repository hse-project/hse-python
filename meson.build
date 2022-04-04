project(
    'hse-python',
    ['cython', 'c'], # until Meson supports Cython as a language
    version: files('VERSION'),
    license: 'Apache-2.0',
    default_options: [
        'prefix=/opt/hse',
        'buildtype=debugoptimized',
        'warning_level=2',
        # Meson for whatever reason chooses not to respect HSE's default
        # options :).
        'force_fallback_for=xxhash,lz4,cjson',
    ],
    meson_version: '>=0.59.0'
)

version_components = meson.project_version().split('.')

hse_python_major_version = version_components[0]
hse_python_minor_version = version_components[1]
hse_python_patch_version = version_components[2]

root_module = 'hse@0@'.format(hse_python_major_version)

cc = meson.get_compiler('c')
cython = meson.get_compiler('cython', native: true)

fs = import('fs')
pymod = import('python')

sh = find_program('sh')
docstrings = find_program('docstrings.py')
pp = find_program('pp.py')
python = pymod.find_installation('python3')

ci = run_command(sh, '-c', '[ ${CI+x} ]', check: false).returncode() == 0

assert(
    cython.version().version_compare('>=0.29.21'),
    'Cython version must be >=0.29.21'
)

# Exported for usage in hse.
project_build_root = meson.project_build_root()

hse_dep = dependency(
    'hse-2',
    version: '>=2.2.0',
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

if not meson.is_subproject()
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

    black = find_program('black', required: false)
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

    run_target(
        'checkoss',
        command: [
            find_program('scripts/dev/checkoss.sh'),
            '@BUILD_ROOT@',
            '@SOURCE_ROOT@',
        ],
    )

    shellcheck = find_program('shellcheck', required: false)
    if shellcheck.found()
        run_target(
            'shellcheck',
            command: [
                find_program('scripts/dev/shellcheck.sh'),
            ]
        )
    endif
endif
