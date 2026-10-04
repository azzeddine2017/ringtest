# src/core/runner.ring

load "stdlibcore.ring"

try
    load "subprocess.ring"
    $bHasSubprocess = true
catch
    $bHasSubprocess = false
done

class TestRunner
    oReporter = NULL
    oParser = NULL
    aTestFiles = []
    aAllSuites = []
    nTotalPassed = 0
    nTotalFailed = 0
    nSuitesPassed = 0
    nSuitesTotal = 0
    cFilter = ""
    bWatchMode = false
    bJsonOutput = false

    func init
        oReporter = new TestReporter()
        oParser = new ArgsParser
        aTestFiles = []
        aAllSuites = []
        return self

    func setFilter cFilter
        this.cFilter = cFilter

    func setWatchMode bWatch
        this.bWatchMode = bWatch

    func setJsonOutput bJson
        this.bJsonOutput = bJson

    func findTestFiles cDirectory
        aResult = []
        scanDirectory(cDirectory, aResult)
        aTestFiles = sort(aResult)
        return aTestFiles

    func runFile cFilePath
        cFilePath = substr(cFilePath, char(92), "/")

        cProjectDir = sysget("RINGTEST_CALLER_DIR")
        if cProjectDir = "" or cProjectDir = NULL
            cProjectDir = sysget("RINGTEST_CWD")
        ok
        if cProjectDir = "" or cProjectDir = NULL
            if substr(cFilePath, "/tests/") > 0
                nPos = substr(cFilePath, "/tests/")
                cProjectDir = left(cFilePath, nPos - 1)
            else
                cProjectDir = currentdir()
            ok
        ok
        cProjectDir = substr(cProjectDir, char(92), "/")
        cFileDir = justfilepath(cFilePath)
        if cFileDir = "" or cFileDir = NULL
            cFileDir = cProjectDir
        ok
        cFileDir = substr(cFileDir, char(92), "/")

        if $bHasSubprocess
            cRingTestHome = sysget("RINGTEST_HOME")
            if cRingTestHome != "" and cRingTestHome != NULL
                cRingTestHome = substr(cRingTestHome, char(92), "/")
                cRingTestSrc = cRingTestHome + "/src/ringtest.ring"
            else
                cRingTestSrc = justfilepath(justfilepath(filename())) + "/ringtest.ring"
                cRingTestSrc = substr(cRingTestSrc, char(92), "/")
            ok

            if not fexists(cRingTestSrc)
                if fexists("G:/ringtest/src/ringtest.ring")
                    cRingTestSrc = "G:/ringtest/src/ringtest.ring"
                else
                    cRingTestSrc = "src/ringtest.ring"
                ok
            ok

            # Read and normalize load paths in test file
            cTestContent = read(cFilePath)
            cTestContent = normalizeLoadPaths(cTestContent, cFileDir, cProjectDir)

            # Create a separate test file so all functions/classes are isolated
            nRand = random(999999)
            cTempTestFile = cProjectDir + "/.ringtest_test_" + string(nRand) + ".ring"
            cTempTestFile = substr(cTempTestFile, char(92), "/")
            writeFileContent(cTempTestFile, cTestContent)

            cTempScript = cProjectDir + "/.ringtest_worker_" + string(nRand) + ".ring"
            cTempScript = substr(cTempScript, char(92), "/")

            cFilterEsc = cFilter
            cCode = 'load "stdlibcore.ring"' + nl +
                    'load "' + cRingTestSrc + '"' + nl +
                    'load "' + cTempTestFile + '"' + nl + nl +
                    'runner = new TestRunner()' + nl +
                    'runner.setFilter("' + cFilterEsc + '")' + nl +
                    'bSuccess = runner.runExecutedSuites("' + cFilePath + '")' + nl +
                    '? "___RINGTEST_RESULTS_START___"' + nl +
                    'runner.printResultsPayload()' + nl +
                    '? "___RINGTEST_RESULTS_END___"' + nl +
                    'if !bSuccess' + nl +
                    '    shutdown(1)' + nl +
                    'ok' + nl

            writeFileContent(cTempScript, cCode)

            oReporter.printHeader(cFilePath)

            cOutFile = cProjectDir + "/.ringtest_out_" + string(nRand) + ".log"
            cOutFile = substr(cOutFile, char(92), "/")

            cCmd = 'ring "' + cTempScript + '" > "' + cOutFile + '" 2>&1'
            nCode = system(cCmd)

            cOutput = ""
            if fexists(cOutFile)
                cOutput = read(cOutFile)
                try
                    remove(cOutFile)
                catch
                done
            ok

            # Clean up temp runner scripts
            try
                remove(cTempTestFile)
            catch
            done
            try
                remove(cTempScript)
            catch
            done

            # Parse results payload from worker stdout
            cCleanOutput = ""
            cPayload = ""
            bInPayload = false

            cOutputClean = substr(cOutput, char(13), "")
            aOutLines = str2list(cOutputClean)

            for cLine in aOutLines
                cTrim = trim(cLine)
                if cTrim = "___RINGTEST_RESULTS_START___"
                    bInPayload = true
                    loop
                but cTrim = "___RINGTEST_RESULTS_END___"
                    bInPayload = false
                    loop
                ok

                if bInPayload
                    cPayload += cLine + nl
                else
                    cCleanOutput += cLine + nl
                ok
            next

            bFileHasSuites = false
            if cPayload != ""
                aNewSuites = parseResultsPayload(cPayload)
                if len(aNewSuites) > 0
                    bFileHasSuites = true
                    for s in aNewSuites
                        add(aAllSuites, s)
                        nSuitesTotal++
                        if s.nFailCount = 0 and len(s.aTests) > 0
                            nSuitesPassed++
                        ok
                        for t in s.aTests
                            if t.bPassed
                                nTotalPassed++
                            else
                                nTotalFailed++
                            ok
                        next
                    next
                ok
            ok

            if !bFileHasSuites
                nSuitesTotal++
                if nCode = 0
                    nSuitesPassed++
                    nTotalPassed++
                else
                    nTotalFailed++
                ok
            ok

            if cCleanOutput != ""
                see cCleanOutput
            ok

            if nCode = 0
                return true
            else
                return false
            ok
        else
            return runFileDirect(cFilePath, cProjectDir)
        ok

    func printResultsPayload
        aSuites = getGlobalSuites()
        for oSuite in aSuites
            ? "[SUITE]"
            ? "name=" + oSuite.cName
            ? "passed=" + string(oSuite.nPassCount)
            ? "failed=" + string(oSuite.nFailCount)
            ? "duration=" + string(oSuite.nTotalDuration)
            for oTest in oSuite.aTests
                cErrMsg = oTest.cErrorMessage
                if cErrMsg != ""
                    cErrMsg = substr(cErrMsg, nl, " -- ")
                    cErrMsg = substr(cErrMsg, char(13), " ")
                ok
                cPassedVal = "0"
                if oTest.bPassed
                    cPassedVal = "1"
                ok
                ? "[TEST]"
                ? "name=" + oTest.cName
                ? "passed=" + cPassedVal
                ? "duration=" + string(oTest.nDuration)
                ? "error=" + cErrMsg
            next
        next

    func parseResultsPayload cPayload
        cPayload = substr(cPayload, char(13), "")
        aLines = str2list(cPayload)
        aParsedSuites = []
        oCurrentSuite = NULL
        oCurTest = NULL
        for cLine in aLines
            cLine = trim(cLine)
            if cLine = ""
                loop
            ok
            if left(cLine, 7) = "[SUITE]"
                oCurrentSuite = new TestSuite("")
                add(aParsedSuites, oCurrentSuite)
                oCurTest = NULL
            but left(cLine, 6) = "[TEST]"
                oCurTest = new TestCase("", NULL)
                if oCurrentSuite != NULL
                    add(oCurrentSuite.aTests, oCurTest)
                ok
            but left(cLine, 5) = "name="
                cVal = strFrom(cLine, 6)
                if oCurTest != NULL
                    oCurTest.cName = cVal
                but oCurrentSuite != NULL
                    oCurrentSuite.cName = cVal
                ok
            but left(cLine, 7) = "passed="
                cVal = strFrom(cLine, 8)
                if oCurTest != NULL
                    oCurTest.bPassed = (cVal = "1" or cVal = "true")
                but oCurrentSuite != NULL
                    oCurrentSuite.nPassCount = number(cVal)
                ok
            but left(cLine, 7) = "failed="
                cVal = strFrom(cLine, 8)
                if oCurrentSuite != NULL
                    oCurrentSuite.nFailCount = number(cVal)
                ok
            but left(cLine, 9) = "duration="
                cVal = strFrom(cLine, 10)
                if oCurTest != NULL
                    oCurTest.nDuration = number(cVal)
                but oCurrentSuite != NULL
                    oCurrentSuite.nTotalDuration = number(cVal)
                ok
            but left(cLine, 6) = "error="
                cVal = strFrom(cLine, 7)
                if oCurTest != NULL
                    oCurTest.cErrorMessage = cVal
                ok
            ok
        next
        return aParsedSuites

    func strFrom cStr, nStart
        nLen = len(cStr)
        if nStart > nLen or nStart <= 0
            return ""
        ok
        return substr(cStr, nStart, nLen - nStart + 1)

    func writeFileContent cFilePath, cContent
        fp = fopen(cFilePath, "w")
        if fp != NULL
            fwrite(fp, cContent)
            fclose(fp)
            return true
        ok
        try
            write(cFilePath, cContent)
            return true
        catch
            return false
        done

    func resolveReportPath cPath, cDefaultName
        if cPath = ""
            cPath = "reports/" + cDefaultName
        ok
        cProjectDir = sysget("RINGTEST_CALLER_DIR")
        if cProjectDir = "" or cProjectDir = NULL
            cProjectDir = sysget("RINGTEST_CWD")
        ok
        if cProjectDir = "" or cProjectDir = NULL
            cProjectDir = currentdir()
        ok
        cProjectDir = substr(cProjectDir, char(92), "/")

        cResolved = cPath
        if left(cResolved, 1) != "/" and substr(cResolved, ":") = 0
            cResolved = cProjectDir + "/" + cResolved
        ok
        cResolved = substr(cResolved, char(92), "/")

        # Ensure destination directory exists
        cDir = justfilepath(cResolved)
        if cDir != "" and cDir != NULL and cDir != "."
            cDir = substr(cDir, char(92), "/")
            try
                if !fexists(cDir)
                    if substr(cDir, ":")
                        system('mkdir "' + substr(cDir, "/", char(92)) + '" 2>nul')
                    else
                        system('mkdir -p "' + cDir + '" 2>/dev/null')
                    ok
                ok
            catch
            done
        ok

        return cResolved

    func runExecutedSuites cFilePath
        nStartTime = clock()

        nSuitesTotal = 0
        nTotalPassed = 0
        nTotalFailed = 0

        aSuites = getGlobalSuites()

        # Run Global beforeAll hooks
        aGlobalBAll = getGlobalBeforeAll()
        for vHook in aGlobalBAll
            safeCall(vHook, NULL)
        next

        for oSuite in aSuites
            nSuitesTotal++
            bSuiteSuccess = true
            oReporter.printSuiteHeader(oSuite.cName)

            nSuiteStart = clock()

            # Run Suite beforeAll hooks
            for vHook in oSuite.aBeforeAll
                safeCall(vHook, oSuite)
            next

            for oTest in oSuite.aTests
                if cFilter != "" and !substr(oTest.cName, cFilter)
                    loop
                ok

                nTestStart = clock()

                # Run Global beforeEach hooks
                aGlobalBEach = getGlobalBeforeEach()
                for vHook in aGlobalBEach
                    safeCall(vHook, oTest)
                next

                # Run Suite beforeEach hooks
                for vHook in oSuite.aBeforeEach
                    safeCall(vHook, oTest)
                next

                # Run test body safely
                try
                    if !isNull(oTest.vCallback)
                        safeCall(oTest.vCallback, oTest)
                    ok
                    oTest.bPassed = true
                    oTest.nDuration = (clock() - nTestStart) / clockspersecond()
                    nTotalPassed++
                    oSuite.nPassCount++
                    oReporter.printTestPass(oTest)
                catch
                    oTest.bPassed = false
                    oTest.cErrorMessage = cCatchError
                    oTest.nDuration = (clock() - nTestStart) / clockspersecond()
                    nTotalFailed++
                    oSuite.nFailCount++
                    bSuiteSuccess = false
                    oReporter.printTestFail(oTest)
                done

                # Run Suite afterEach hooks
                for vHook in oSuite.aAfterEach
                    safeCall(vHook, oTest)
                next

                # Run Global afterEach hooks
                aGlobalAEach = getGlobalAfterEach()
                for vHook in aGlobalAEach
                    safeCall(vHook, oTest)
                next
            next

            # Run Suite afterAll hooks
            for vHook in oSuite.aAfterAll
                safeCall(vHook, oSuite)
            next

            oSuite.nTotalDuration = (clock() - nSuiteStart) / clockspersecond()

            if bSuiteSuccess
                nSuitesPassed++
            ok
            ? ""
        next

        # Run Global afterAll hooks
        aGlobalAAll = getGlobalAfterAll()
        for vHook in aGlobalAAll
            safeCall(vHook, NULL)
        next

        return (nTotalFailed = 0)

    func runFileDirect cFilePath, cProjectDir
        clearGlobalSuites()

        oReporter.printHeader(cFilePath)
        nStartTime = clock()

        cFilePath = substr(cFilePath, char(92), "/")

        # 1. Resolve Project Root
        if cProjectDir = "" or cProjectDir = NULL
            cProjectDir = sysget("RINGTEST_CALLER_DIR")
        ok
        if cProjectDir = "" or cProjectDir = NULL
            cProjectDir = sysget("RINGTEST_CWD")
        ok
        if cProjectDir = "" or cProjectDir = NULL
            if substr(cFilePath, "/tests/") > 0
                nPos = substr(cFilePath, "/tests/")
                cProjectDir = left(cFilePath, nPos - 1)
            else
                cProjectDir = currentdir()
            ok
        ok

        cFileDir = justfilepath(cFilePath)
        if cFileDir = "" or cFileDir = NULL
            cFileDir = cProjectDir
        ok

        # Normalize paths
        cProjectDir = substr(cProjectDir, char(92), "/")
        cFileDir = substr(cFileDir, char(92), "/")

        cOrigDir = currentdir()
        try
            chdir(cProjectDir)
        catch
        done

        # Read and resolve relative load paths
        cCode = read(cFilePath)
        cCode = normalizeLoadPaths(cCode, cFileDir, cProjectDir)

        # Separate load statements from test definitions
        aLines = str2list(cCode)
        cTestCode = ""
        for cLine in aLines
            cTrim = trim(cLine)
            if left(lower(cTrim), 5) = "load "
                try
                    eval(cTrim)
                catch
                    oReporter.printLoadError(cFilePath, cCatchError, cTrim)
                    nTotalFailed++
                    try chdir(cOrigDir) catch done
                    return false
                done
            else
                cTestCode += cLine + nl
            ok
        next

        try
            eval(cTestCode)
        catch
            oReporter.printLoadError(cFilePath, cCatchError, "")
            nTotalFailed++
            try chdir(cOrigDir) catch done
            return false
        done

        aSuites = getGlobalSuites()

        # Run Global beforeAll hooks
        aGlobalBAll = getGlobalBeforeAll()
        for vHook in aGlobalBAll
            safeCall(vHook, NULL)
        next

        for oSuite in aSuites
            add(aAllSuites, oSuite)
            nSuitesTotal++
            bSuiteSuccess = true
            oReporter.printSuiteHeader(oSuite.cName)

            nSuiteStart = clock()

            # Run Suite beforeAll hooks
            for vHook in oSuite.aBeforeAll
                safeCall(vHook, oSuite)
            next

            for oTest in oSuite.aTests
                if cFilter != "" and !substr(oTest.cName, cFilter)
                    loop
                ok

                nTestStart = clock()

                # Run Global beforeEach hooks
                aGlobalBEach = getGlobalBeforeEach()
                for vHook in aGlobalBEach
                    safeCall(vHook, oTest)
                next

                # Run Suite beforeEach hooks
                for vHook in oSuite.aBeforeEach
                    safeCall(vHook, oTest)
                next

                # Run test body safely
                try
                    if !isNull(oTest.vCallback)
                        safeCall(oTest.vCallback, oTest)
                    ok
                    oTest.bPassed = true
                    oTest.nDuration = (clock() - nTestStart) / clockspersecond()
                    nTotalPassed++
                    oSuite.nPassCount++
                    oReporter.printTestPass(oTest)
                catch
                    oTest.bPassed = false
                    oTest.cErrorMessage = cCatchError
                    oTest.nDuration = (clock() - nTestStart) / clockspersecond()
                    nTotalFailed++
                    oSuite.nFailCount++
                    bSuiteSuccess = false
                    oReporter.printTestFail(oTest)
                done

                # Run Suite afterEach hooks
                for vHook in oSuite.aAfterEach
                    safeCall(vHook, oTest)
                next

                # Run Global afterEach hooks
                aGlobalAEach = getGlobalAfterEach()
                for vHook in aGlobalAEach
                    safeCall(vHook, oTest)
                next
            next

            # Run Suite afterAll hooks
            for vHook in oSuite.aAfterAll
                safeCall(vHook, oSuite)
            next

            oSuite.nTotalDuration = (clock() - nSuiteStart) / clockspersecond()

            if bSuiteSuccess
                nSuitesPassed++
            ok
            ? ""
        next

        # Run Global afterAll hooks
        aGlobalAAll = getGlobalAfterAll()
        for vHook in aGlobalAAll
            safeCall(vHook, NULL)
        next

        try
            chdir(cOrigDir)
        catch
        done

        return (nTotalFailed = 0)

    func runAll
        nGlobalStart = clock()
        aAllSuites = []
        nTotalPassed = 0
        nTotalFailed = 0
        nSuitesPassed = 0
        nSuitesTotal = 0

        if len(aTestFiles) = 0
            ? oReporter.cYellow + "No test files found matching *_test.ring or test_*.ring" + oReporter.cReset
            return false
        ok

        for cFile in aTestFiles
            runFile(cFile)
        next

        nTotalTime = (clock() - nGlobalStart) / clockspersecond()
        
        if bJsonOutput
            oReporter.printJSON(nSuitesPassed, nSuitesTotal, nTotalPassed, nTotalFailed, nTotalTime)
        else
            oReporter.printSummary(nSuitesPassed, nSuitesTotal, nTotalPassed, nTotalFailed, nTotalTime)
        ok

        # Generate HTML report if requested
        if oParser != NULL and oParser.bHtmlReport
            cHtmlPath = resolveReportPath(oParser.cHtmlReportPath, "test-report.html")
            oReporter.generateHtmlReport(aAllSuites, cHtmlPath, nSuitesPassed, nSuitesTotal, nTotalPassed, nTotalFailed, nTotalTime)
        ok

        # Generate JUnit XML report if requested
        if oParser != NULL and oParser.bJunitReport
            cJunitPath = resolveReportPath(oParser.cJunitReportPath, "test-report.xml")
            oReporter.generateJunitReport(aAllSuites, cJunitPath, nSuitesPassed, nSuitesTotal, nTotalPassed, nTotalFailed, nTotalTime)
        ok

        return (nTotalFailed = 0)

    func runWatch
        ? oReporter.cCyan + "==========================================================" + oReporter.cReset
        ? oReporter.cCyan + "  Watch mode enabled. Waiting for file changes..." + oReporter.cReset
        ? oReporter.cCyan + "  Press Ctrl+C to exit." + oReporter.cReset
        ? oReporter.cCyan + "==========================================================" + oReporter.cReset
        ? ""

        # Resolve watch directory from caller working directory
        cWatchDir = sysget("RINGTEST_CALLER_DIR")
        if cWatchDir = "" or cWatchDir = NULL
            cWatchDir = sysget("RINGTEST_CWD")
        ok
        if cWatchDir = "" or cWatchDir = NULL
            cWatchDir = "."
        ok
        if oParser != NULL and oParser.cTargetDirectory != "" and oParser.cTargetDirectory != "."
            cWatchDir = oParser.cTargetDirectory
        ok
        cWatchDir = substr(cWatchDir, char(92), "/")
 
        # 1. Initial test run
        nTotalPassed = 0
        nTotalFailed = 0
        nSuitesPassed = 0
        nSuitesTotal = 0
        findTestFiles(cWatchDir)
        runAll()

        cLastSnapshot = getFileSnapshot(cWatchDir)

        # 2. Watch loop: only re-runs when a file is modified, added, or deleted
        while true
            sleep(1)
            cCurrentSnapshot = getFileSnapshot(cWatchDir)
            if cCurrentSnapshot != cLastSnapshot
                cLastSnapshot = cCurrentSnapshot
                ? ""
                ? oReporter.cYellow + "--------------------------------------------------" + oReporter.cReset
                ? oReporter.cYellow + "  File change detected. Re-running tests..." + oReporter.cReset
                ? oReporter.cYellow + "--------------------------------------------------" + oReporter.cReset
                ? ""
                nTotalPassed = 0
                nTotalFailed = 0
                nSuitesPassed = 0
                nSuitesTotal = 0
                findTestFiles(cWatchDir)
                runAll()
            ok
        end

    func getFileSnapshot cDir
        if cDir = "" or cDir = NULL
            cDir = "."
        ok
        aFiles = []
        scanDirForSnapshot(cDir, aFiles)
        cSignature = ""
        for aItem in aFiles
            cSignature += aItem[1] + ":" + string(aItem[2]) + ":" + string(aItem[3]) + ";"
        next
        return cSignature
 
    func scanDirForSnapshot cPath, aOutList
        aEntries = dir(cPath)
        for entry in aEntries
            cName = entry[1]
            bIsDir = entry[2]

            if cName = "." or cName = ".."
                loop
            ok
            if left(cName, 1) = "." or cName = "bin" or cName = ".git"
                loop
            ok

            cFullPath = cPath + "/" + cName
            cFullPath = substr(cFullPath, char(92), "/")

            if bIsDir
                if cName != ".git" and cName != ".rvenv" and cName != ".ringenv" and cName != "bin"
                    scanDirForSnapshot(cFullPath, aOutList)
                ok
            else
                if substr(cName, ".ring") or substr(cName, ".conf") or substr(cName, ".json")
                    nSize = getfilesize(cFullPath)
                    cContent = read(cFullPath)
                    cHash = ""
                    try
                        cHash = SHA256(cContent)
                    catch
                        cHash = string(len(cContent))
                    done
                    aOutList + [cFullPath, nSize, cHash]
                ok
            ok
        next

    private

    func safeCall vFunc, oArg
        if isNull(vFunc) return ok
        try
            call vFunc()
        catch
            if substr(cCatchError, "Calling function with less number of parameters") > 0
                call vFunc(oArg)
            else
                raise(cCatchError)
            ok
        done

    func scanDirectory cPath, aOutList
        aEntries = dir(cPath)
        for entry in aEntries
            cName = entry[1]
            bIsDir = entry[2]

            if cName = "." or cName = ".."
                loop
            ok

            cFullPath = cPath + "/" + cName
            cFullPath = substr(cFullPath, char(92), "/")

            if bIsDir
                if cName != ".git" and cName != ".rvenv" and cName != ".ringenv" and cName != "bin"
                    scanDirectory(cFullPath, aOutList)
                ok
            else
                if isTestFile(cName)
                    aOutList + cFullPath
                ok
            ok
        next

    func isTestFile cName
        if lower(cName) = "main.ring" or lower(cName) = "package.ring"
            return false
        ok

        nLen = len(cName)
        if nLen >= 10 and right(cName, 10) = "_test.ring"
            return true
        ok
        if nLen >= 10 and left(cName, 5) = "test_" and right(cName, 5) = ".ring"
            return true
        ok
        return false

    func normalizeLoadPaths cCode, cFileDir, cProjectDir
        cResult = ""
        aLines = str2list(cCode)
        for cLine in aLines
            cTrim = trim(cLine)

            # Match: load "..."
            if left(lower(cTrim), 5) = "load " and substr(cTrim, '"') > 0
                nStart = substr(cTrim, '"')
                cRest = strFrom(cTrim, nStart + 1)
                nEnd = substr(cRest, '"')
                if nEnd > 0
                    cPath = left(cRest, nEnd - 1)

                    if substr(cPath, ":") or left(cPath, 1) = "/" or
                       cPath = "stdlibcore.ring" or
                       cPath = "stdlib.ring" or
                       cPath = "ringtest.ring" or
                       cPath = "libcurl.ring" or
                       cPath = "jsonlib.ring" or
                       cPath = "zipengine.ring"
                        cResult += cLine + nl
                        loop
                    ok

                    cCand1 = cFileDir + "/" + cPath
                    cCand1 = substr(cCand1, char(92), "/")

                    cCand2 = cProjectDir + "/" + cPath
                    cCand2 = substr(cCand2, char(92), "/")

                    if fexists(cCand2)
                        cResult += 'load "' + cCand2 + '"' + nl
                    but fexists(cCand1)
                        cResult += 'load "' + cCand1 + '"' + nl
                    else
                        cResult += cLine + nl
                    ok
                else
                    cResult += cLine + nl
                ok
            else
                cResult += cLine + nl
            ok
        next
        return cResult