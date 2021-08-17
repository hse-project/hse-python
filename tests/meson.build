if get_option('b_sanitize') != 'none'
    subdir_done()
endif

pytest = find_program('pytest', required: true)
test_runner = find_program('test-runner')

env = environment({
    'PYTHONPATH': meson.project_build_root(),
    'HSE_TEST_RUNNER_RUNNER': 'pytest',
})

add_test_setup(
    'ci',
    exe_wrapper: [
        test_runner,
        '--',
    ],
    env: env,
    is_default: not meson.is_subproject()
)

suites = [
    'cursor',
    'kvdb',
    'kvs',
    'limits',
    'transaction',
    'version',
]

foreach s : suites
    test(
        '@0@'.format(s),
        pytest,
        args: [
            '--tap-stream',
            'test_@0@.py'.format(s),
            get_option('experimental') ? ['--experimental'] : [],
        ],
        env: env,
        suite: ['unit'],
        protocol: 'tap',
        workdir: meson.current_source_dir(),
        depends: [
            extension_modules,
            init_py,
        ],
        timeout: 60
    )
endforeach
