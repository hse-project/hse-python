project(
    'hse-python',
    'c',
    version: files('VERSION'),
    license: 'Apache-2.0',
    default_options: [
        'prefix=/opt/hse',
        'buildtype=debugoptimized',
        'warning_level=2',
        # Meson for whatever reason chooses not to respect HSE's default
        # options :).
        'force_fallback_for=lz4,cjson',
    ],
    meson_version: '>=0.59.0'
)

# Move this back into the project() call when hse-python depends on
# meson_version >=0.64.0.
add_languages('cython', native: true)

version_components = meson.project_version().split('.')

hse_python_major_version = version_components[0].to_int()
hse_python_minor_version = version_components[1].to_int()
hse_python_patch_version = version_components[2].to_int()

root_module = 'hse@0@'.format(hse_python_major_version)

cc = meson.get_compiler('c')
cython = meson.get_compiler('cython', native: true)

fs = import('fs')
pymod = import('python')

sh = find_program('sh')
docstrings = find_program('scripts/build/docstrings.py')
pp = find_program('scripts/build/pp.py')
python = pymod.find_installation('python3')

ci = run_command(sh, '-c', '[ ${CI+x} ]', check: false).returncode() == 0

assert(
    cython.version().version_compare('>=0.29.21'),
    'Cython version must be >=0.29.21'
)

# Exported for usage in hse.
project_build_root = meson.project_build_root()

# https://github.com/cython/cython/issues/5132
add_project_arguments(
    cc.get_supported_arguments('-Wno-error=unused-parameter'),
    language: 'c'
)

hse_dep = dependency(
    'hse-@0@'.format(hse_python_major_version),
    version: [
        '>=@0@.0.0'.format(hse_python_major_version),
        '<@0@.0.0'.format(hse_python_major_version + 1)
    ],
    default_options: [
        'cli=false',
        'docs=disabled',
        'tests=false',
        'tools=disabled',
        'samples=false',
        'bindings=none',
    ]
)

subdir('hse@0@'.format(hse_python_major_version))

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

black = find_program('black', required: false, disabler: true)
run_target(
    'format',
    command: [
        black,
        meson.project_source_root(),
    ]
)

run_target(
    'format-check',
    command: [
        black,
        meson.project_source_root(),
        '--check',
        '--diff',
    ]
)

run_target(
    'checkoss',
    command: [
        find_program('scripts/dev/checkoss.sh'),
        '@BUILD_ROOT@',
        '@SOURCE_ROOT@',
    ]
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
