project(
    'hse-python',
    version: '1.0.0',
    default_options: [
        'buildtype=debugoptimized',
        'warning_level=2',
    ],
    meson_version: '>=0.57',
)

fs = import('fs')
pymod = import('python')

docstrings = find_program('docstrings.py', required: true)
cython = find_program('cython', required: true)
python = pymod.find_installation(
    'python3',
    required: true,
    modules: [
        'toml',
    ],
)

build_number_result = run_command(
    'sh',
    '-c',
    '[ -n "$BUILD_NUMBER" ]'
)
in_ci = build_number_result.returncode() == 0

black = find_program('black', required: in_ci)
if black.found()
    black_command = [
        black,
        meson.project_source_root(),
    ]

    if in_ci
        black_command += [
            '--check',
            '--diff',
        ]
    endif

    run_target(
        'black',
        command: black_command,
    )
endif

# Exported for usage in hse.
project_build_root = meson.project_build_root()
project_source_root = meson.project_source_root()

hse_dep = dependency(
    'hse-1',
    version: '>=1.10',
    required: true,
    fallback: ['hse', 'hse_dep'],
    default_options: [
        'cli=false',
        'tests=[]',
        'tools=false',
        'samples=false',
        'bindings-python=false',
    ],
)

subdir('hse')

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
)
