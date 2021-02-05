project(
	'hse-python',
	version: '1.0.0',
	default_options: [
		'buildtype=debugoptimized',
	],
)

pymod = import('python')

docstrings = find_program('docstrings.py', required: true)
cython = find_program('cython', required: true)
python = pymod.find_installation('python', required: true)

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

project_build_root = meson.project_build_root()

if get_option('tests')
	subdir('test')
endif
