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
        ? "ringtest version 1.0.0"
        return
    ok

    runner = new TestRunner()
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
    ? "  ring main.ring [options] [target_path]"
    ? ""
    ? "Options:"
    ? "  -h, --help        Show this help documentation"
    ? "  -v, --version     Display the current ringtest version"
    ? "  --filter=<text>   Filter executed tests by description"
    ? "  -w, --watch       Watch mode: re-run tests on file changes"
    ? "  -j, --json        Output results in JSON format"
    ? ""
    ? "Examples:"
    ? "  ring main.ring                     # Discover and run all tests"
    ? "  ring main.ring tests/              # Run all tests in 'tests/' folder"
    ? "  ring main.ring tests/sample_test.ring # Run specific test file"
    ? "  ring main.ring --filter=math       # Run only tests matching 'math'"
    ? "  ring main.ring --watch             # Watch mode"
    ? "  ring main.ring --json              # JSON output"
    ? "=========================================================="