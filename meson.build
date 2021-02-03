project(
	'hse-python',
	version: '1.10.0',
)

pymod = import('python')

docstrings = find_program('docstrings.py', required: true)
cython = find_program('cython', required: get_option('use-cython'))
python = pymod.find_installation(
	'python',
	required: true,
)

if get_option('hse-lib-dir') != ''
	hse_dep = find_library('hse-1', required: true, dirs: get_option('hse-lib-dir'))
else
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
endif

subdir('hse')

if get_option('tests')
	subdir('test')
endif
