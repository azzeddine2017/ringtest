# main.ring

load "stdlibcore.ring"
load "src/ringtest.ring"

func main
   
    oParser = new ArgsParser
    oParser.parse(sysargv)

    if oParser.bShowHelp
        showHelp()
        return
    ok

    if oParser.bShowVersion
        ? "ringtest version 1.0.4"
        return
    ok

    runner = new TestRunner()
    runner.oParser = oParser
    runner.setFilter(oParser.cFilter)
    runner.setWatchMode(oParser.bWatchMode)
    runner.setJsonOutput(oParser.bJsonOutput)

    if oParser.cTargetFile != ""
        nStart = clock()
        bSuccess = runner.runFile(oParser.cTargetFile)
        nTotalTime = (clock() - nStart) / clockspersecond()
        if runner.bJsonOutput
            runner.oReporter.printJSON(runner.nSuitesPassed, runner.nSuitesTotal, runner.nTotalPassed, runner.nTotalFailed, nTotalTime)
        else
            runner.oReporter.printSummary(runner.nSuitesPassed, runner.nSuitesTotal, runner.nTotalPassed, runner.nTotalFailed, nTotalTime)
        ok

        # Generate HTML report if requested
        if oParser.bHtmlReport
            cHtmlPath = runner.resolveReportPath(oParser.cHtmlReportPath, "test-report.html")
            runner.oReporter.generateHtmlReport(runner.aAllSuites, cHtmlPath, runner.nSuitesPassed, runner.nSuitesTotal, runner.nTotalPassed, runner.nTotalFailed, nTotalTime)
        ok

        # Generate JUnit XML report if requested
        if oParser.bJunitReport
            cJunitPath = runner.resolveReportPath(oParser.cJunitReportPath, "test-report.xml")
            runner.oReporter.generateJunitReport(runner.aAllSuites, cJunitPath, runner.nSuitesPassed, runner.nSuitesTotal, runner.nTotalPassed, runner.nTotalFailed, nTotalTime)
        ok

        if !bSuccess
            shutdown(1)
        ok
    else
        runner.findTestFiles(oParser.cTargetDirectory)
        if oParser.bWatchMode
            runner.runWatch()
        else
            bSuccess = runner.runAll()
            if !bSuccess
                shutdown(1)
            ok
        ok
    ok

func showHelp
    ? "=========================================================="
    ? "  ringtest - The Modern Test Runner for Ring Language     "
    ? "=========================================================="
    ? "Usage:"
    ? "  ringtest [options] [target_path]"
    ? ""
    ? "Options:"
    ? "  -h, --help           Show this help documentation"
    ? "  -v, --version        Display the current ringtest version"
    ? "  --filter=<text>      Filter executed tests by description"
    ? "  -w, --watch          Watch mode: re-run tests on file changes"
    ? "  -j, --json           Output results in JSON format"
    ? "  --html[=<path>]      Generate modern interactive HTML dashboard"
    ? "  --junit[=<path>]     Generate JUnit XML report for CI/CD"
    ? "  --xml[=<path>]       Alias for --junit"
    ? ""
    ? "Lifecycle Hooks:"
    ? "  beforeAll(func), beforeEach(func), afterEach(func), afterAll(func)"
    ? ""
    ? "Examples:"
    ? "  ringtest                        # Discover and run all tests"
    ? "  ringtest tests/                 # Run all tests in 'tests/' folder"
    ? "  ringtest tests/sample_test.ring # Run specific test file"
    ? "  ringtest --filter=math          # Run only tests matching 'math'"
    ? "  ringtest --watch                # Watch mode"
    ? "  ringtest --html                 # Generate 'test-report.html'"
    ? "  ringtest --junit=report.xml     # Generate JUnit XML report"
    ? "=========================================================="