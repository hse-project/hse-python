if get_option('b_sanitize') != 'none'
    subdir_done()
endif

test_runner = find_program('test-runner')

env = environment({
    'PYTHONPATH': meson.project_build_root(),
    'HSE_TEST_RUNNER_RUNNER': 'python',
})

wrapper = [
    python,
    test_runner,
    '--',
]

add_test_setup(
    'default',
    env: env,
    exe_wrapper: wrapper,
    is_default: not meson.is_subproject()
)

add_test_setup(
    'ci',
    exe_wrapper: wrapper,
    env: env
)

tests = [
    'cursor',
    'hse',
    'kvdb',
    'kvs',
    'limits',
    'transaction',
    'version',
]

foreach t : tests
    test(
        'python-@0@'.format(t),
        python,
        args: [
            meson.project_source_root() / 'tests/test_@0@.py'.format(t),
            get_option('experimental') ? ['--experimental'] : [],
        ],
        suite: ['unit'],
        workdir: meson.current_source_dir(),
        env: env,
        depends: [
            extension_modules,
            init_py,
        ],
        timeout: 60
    )
endforeach
