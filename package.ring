

aPackageInfo = [
	:name = "ringtest",
	:description = "Modern and ultra-fast unit testing framework for the Ring Programming Language",
	:folder = "ringtest",
	:developer = "Azzeddine Remmal",
	:email = "azzeddine.remmal@gmail.com",
	:license = "MIT License",
	:version = "1.0.3",
	:ringversion = "1.21",
	:versions = [
		[
			:version = "1.0.3",
			:branch = "main"
		]
	],
	:libs = [
		[
			:name = "stdlib",
			:version = "1.0.24",
			:providerusername = ""
		],
		[
			:name = "ringsubprocess",
			:version = "1.0.5",
			:providerusername = "Azzeddine2017"
		]
	],
	:files = [
		"main.ring",
		"LICENSE",
		".gitignore",
		"README.md",
		"package.ring",
		"setup.bat",
		"setup.sh",
		"src/ringtest.ring",
		"src/assertions/expectation.ring",
		"src/core/suite.ring",
		"src/core/runner.ring",
		"src/core/worker.ring",
		"src/core/reporter.ring",
		"src/core/mock.ring",
		"src/cli/args_parser.ring",
		"tests/sample_test.ring",
		"tests/math_test.ring",
		"tests/string_test.ring",
		"tests/error_test.ring",
		"tests/hooks_test.ring",
		"tests/context_test.ring",
		"tests/mock_test.ring",
		"tests/diagnostic_demo_test.ring"
	],
	:ringfolderfiles = [
        "bin/ringtest.bat",
		"bin/ringtest",
		"bin/load/ringtest.ring"
	],
	:windowsfiles = [

	],
	:linuxfiles = [

	],
	:macosfiles = [

	],
	:windowsringfolderfiles = [
		"bin/ringtest.bat"
	],
	:linuxringfolderfiles = [
		"bin/ringtest"
	],
	:macosringfolderfiles = [
		"bin/ringtest"
	],
	:run = "ring main.ring",
	:setup = "",
	:windowssetup = "",
	:linuxsetup = "",
	:macossetup = "",
	:ubuntusetup = "",
	:fedorasetup = "",
	:remove = "",
	:windowsremove = "",
	:linuxremove = "",
	:macosremove = "",
	:ubunturemove = "",
	:fedoraremove = "",
	:remotefolder = "ringtest",
	:branch = "main",
	:providerusername = "Azzeddine2017",
	:providerwebsite = "github.com"
]