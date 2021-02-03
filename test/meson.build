pytest = find_program('pytest', required: true)

env = environment({
	'PYTHONPATH': meson.project_build_root(),
})

suites = {
	'cursor': false,
	'experimental': false,
	'hse': false,
	'kvdb': false,
	'kvs': false,
	'limits': true,
	'params': false,
	'transaction': false,
}

foreach s, is_parallel : suites
	test(
		'pytest',
		pytest,
		args: [
			'--tap-stream',
			meson.current_source_dir() / 'test_@0@.py'.format(s),
		],
		env: env,
		suite: ['unit', s],
		protocol: 'tap',
		# Kvdbs can only be accessed once at a time
		is_parallel: is_parallel,
	)
endforeach
