project(
	'hse-python',
	version: '1.0.0',
	default_options: [
		'buildtype=debugoptimized',
		'warning_level=2',
	],
)

pymod = import('python')

docstrings = find_program('docstrings.py', required: true)
cython = find_program('cython', required: true)
python = pymod.find_installation('python3', required: true)

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

hse_dep = dependency(
	'hse-1',
	version: '>=1.10',
	required: true,
	fallback: ['hse', 'hse_dep'],
	default_options: [
		'tests=false',
		'tools=false',
		'samples=false',
	],
)

subdir('hse')

if get_option('tests')
	subdir('test')
endif

# TODO: remove when minimum Meson version moves to 0.57
if meson.version().version_compare('>=0.57')
	run_target(
		'python-repl',
		env: environment({
			'PYTHONPATH': meson.project_build_root(),
		}),
	)
endif
