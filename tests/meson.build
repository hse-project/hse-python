pytest = find_program('pytest', required: true)

env = environment({
    'PYTHONPATH': '@0@:@1@'.format(meson.project_build_root(), meson.project_source_root()),
})

if get_option('tests-dir') == ''
    tests_dir = meson.project_build_root() / 'hse-python-tests'
else
    tests_dir = get_option('tests-dir')
endif

if not fs.exists(tests_dir)
    run_command(
        'mkdir',
        tests_dir,
        check: true,
    )
endif

suites = [
    'cursor',
    'experimental',
    'kvdb',
    'kvs',
    'limits',
    'transaction',
    'version',
]

foreach s : suites
    home_dir = tests_dir / s
    if not fs.exists(home_dir)
        run_command(
            'mkdir',
            home_dir,
            check: true,
        )
    endif

    test(
        '@0@'.format(s),
        pytest,
        args: [
            '--tap-stream',
            meson.current_source_dir() / 'test_@0@.py'.format(s),
            '--home',
            home_dir,
        ],
        env: env,
        suite: ['unit'],
        protocol: 'tap',
        depends: [
            extension_modules,
        ],
    )
endforeach
