# main.ring

load "stdlibcore.ring"
load "src/ringtest.ring"
try
    load "AlQalam.ring"
catch
done

cVersion = "1.2.0"
func main
   
    oParser = new ArgsParser
    oParser.parse(sysargv)

    if oParser.bShowHelp
        showHelp()
        return
    ok

    if oParser.bShowVersion
        ? "ringtest version " + cVersion
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
            runner.oReporter.printJSON(runner.nSuitesPassed, runner.nSuitesTotal, runner.nTotalPassed, runner.nTotalFailed, nTotalTime, runner.nTotalSkipped)
        else
            runner.oReporter.printSummary(runner.nSuitesPassed, runner.nSuitesTotal, runner.nTotalPassed, runner.nTotalFailed, nTotalTime, runner.nTotalSkipped)
        ok

        # Generate HTML report if requested
        if oParser.bHtmlReport
            cHtmlPath = runner.resolveReportPath(oParser.cHtmlReportPath, "test-report.html")
            runner.oReporter.generateHtmlReport(runner.aAllSuites, cHtmlPath, runner.nSuitesPassed, runner.nSuitesTotal, runner.nTotalPassed, runner.nTotalFailed, nTotalTime, runner.nTotalSkipped)
        ok

        # Generate JUnit XML report if requested
        if oParser.bJunitReport
            cJunitPath = runner.resolveReportPath(oParser.cJunitReportPath, "test-report.xml")
            runner.oReporter.generateJunitReport(runner.aAllSuites, cJunitPath, runner.nSuitesPassed, runner.nSuitesTotal, runner.nTotalPassed, runner.nTotalFailed, nTotalTime, runner.nTotalSkipped)
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
    cBold  = char(27) + "[1m"
    cCyan  = char(27) + "[36m"
    cGreen = char(27) + "[32m"
    cGray  = char(27) + "[90m"
    cReset = char(27) + "[0m"

    ? cCyan + cBold + "==========================================================" + cReset
    ? cCyan + cBold + "  ringtest - The Modern Test Runner for Ring Language     " + cReset
    ? cCyan + cBold + "==========================================================" + cReset
    ? ""
    ? cBold + "Usage:" + cReset
    ? "  ringtest [options] [target_path]"
    ? ""
    ? cBold + "Options:" + cReset
    ? "  " + cGreen + "-h, --help" + cReset + "              Show this help documentation"
    ? "  " + cGreen + "-v, --version" + cReset + "           Display the current ringtest version"
    ? "  " + cGreen + "--filter=<text>" + cReset + "         Filter executed tests by description"
    ? "  " + cGreen + "-w, --watch" + cReset + "             Watch mode: re-run tests on file changes"
    ? "  " + cGreen + "-j, --json" + cReset + "              Output results in machine-readable JSON format"
    ? "  " + cGreen + "--html[=<path>]" + cReset + "         Generate modern interactive HTML dashboard"
    ? "  " + cGreen + "--junit[=<path>]" + cReset + "        Generate standard JUnit XML report for CI/CD"
    ? "  " + cGreen + "--xml[=<path>]" + cReset + "          Alias for --junit"
    ? ""
    ? cBold + "Lifecycle Hooks:" + cReset
    ? "  " + cGray + "Suite Scope:" + cReset + "   beforeAll(func), beforeEach(func), afterEach(func), afterAll(func)"
    ? "  " + cGray + "Global Scope:" + cReset + "  beforeAll(func), beforeEach(func), afterEach(func), afterAll(func)"
    ? ""
    ? cBold + "Examples:" + cReset
    ? "  ringtest                           " + cGray + "# Discover and run all tests in ./tests" + cReset
    ? "  ringtest tests/                    " + cGray + "# Run all tests in 'tests/' folder" + cReset
    ? "  ringtest tests/sample_test.ring    " + cGray + "# Run a specific test file" + cReset
    ? "  ringtest --filter=math             " + cGray + "# Run only tests matching 'math'" + cReset
    ? "  ringtest --watch                   " + cGray + "# Watch mode: auto re-run on changes" + cReset
    ? "  ringtest --html                    " + cGray + "# Generate 'reports/test-report.html'" + cReset
    ? "  ringtest --junit                   " + cGray + "# Generate 'reports/test-report.xml'" + cReset
    ? "  ringtest --html --junit            " + cGray + "# Generate both HTML & JUnit XML reports" + cReset
    ? "  ringtest --html=custom/report.html " + cGray + "# Generate HTML report at custom path" + cReset
    ? ""
    ? cCyan + "==========================================================" + cReset