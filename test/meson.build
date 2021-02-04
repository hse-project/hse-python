pytest = find_program('pytest', required: true)

env = environment({
	'PYTHONPATH': project_build_root,
})

# Name of suite with whether or not it can be parallel. KVDBs can only be
# opened one at a time.
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
		is_parallel: is_parallel,
	)
endforeach
