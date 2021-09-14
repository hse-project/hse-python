if get_option('b_sanitize') != 'none'
    subdir_done()
endif

pytest = find_program('pytest', required: true)
test_runner = find_program('test-runner')

env = environment({
    'PYTHONPATH': meson.project_build_root(),
    'HSE_TEST_RUNNER_RUNNER': 'pytest',
})

wrapper = [
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

test(
    'python-bindings',
    pytest,
    args: [
        '--tap-stream',
        '-s',
        meson.current_source_dir(),
        get_option('experimental') ? ['--experimental'] : [],
    ],
    suite: ['unit'],
    protocol: 'tap',
    workdir: meson.current_source_dir(),
    env: env,
    depends: [
        extension_modules,
        init_py,
    ],
    timeout: 60
)
