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
    nTotalSkipped = 0
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

            cTempResFile = cProjectDir + "/.ringtest_res_" + string(nRand) + ".ring"
            cTempResFile = substr(cTempResFile, char(92), "/")

            cFilterEsc = cFilter
            cCode = 'load "stdlibcore.ring"' + nl +
                    'load "' + cRingTestSrc + '"' + nl +
                    'load "' + cTempTestFile + '"' + nl + nl +
                    'runner = new TestRunner()' + nl +
                    'runner.setFilter("' + cFilterEsc + '")' + nl +
                    'bSuccess = runner.runExecutedSuites("' + cFilePath + '")' + nl +
                    'runner.saveResultsPayload("' + cTempResFile + '")' + nl +
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

            aOutLines = str2list(cOutput)

            for cLine in aOutLines
                cTrim = cleanLine(cLine)
                if cTrim = "___RINGTEST_RESULTS_START___"
                    bInPayload = true
                    loop
                but cTrim = "___RINGTEST_RESULTS_END___"
                    bInPayload = false
                    loop
                ok

                if bInPayload
                    cPayload += cTrim + nl
                else
                    cCleanOutput += cLine + nl
                ok
            next

            # Retrieve parsed suites from result file or stdout payload
            aNewSuites = []
            if fexists(cTempResFile)
                aNewSuites = loadResultsPayload(cTempResFile)
                try
                    remove(cTempResFile)
                catch
                done
            ok

            if len(aNewSuites) = 0 and cPayload != ""
                aNewSuites = parseResultsPayload(cPayload)
            ok

            bFileHasSuites = false
            if len(aNewSuites) > 0
                bFileHasSuites = true
                for s in aNewSuites
                    add(aAllSuites, s)
                    nSuitesTotal++
                    if s.nFailCount = 0 and len(s.aTests) > 0
                        nSuitesPassed++
                    ok
                    nTotalSkipped += s.nSkipCount
                    for t in s.aTests
                        if t.bSkipped
                            # Already counted via suite or single test
                        but t.bPassed
                            nTotalPassed++
                        else
                            nTotalFailed++
                        ok
                    next
                next
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

    func saveResultsPayload cFilePath
        cScript = "return [" + nl
        for sIdx = 1 to len(aGlobalTestSuites)
            cScript += "  [" + '"' + escapeRingString(aGlobalTestSuites[sIdx].cName) + '", ' +
                       string(aGlobalTestSuites[sIdx].nPassCount) + ", " +
                       string(aGlobalTestSuites[sIdx].nFailCount) + ", " +
                       string(aGlobalTestSuites[sIdx].nSkipCount) + ", " +
                       string(aGlobalTestSuites[sIdx].nTotalDuration) + ", [" + nl
            for tIdx = 1 to len(aGlobalTestSuites[sIdx].aTests)
                oTest = aGlobalTestSuites[sIdx].aTests[tIdx]
                cPassFlag = "0"
                if oTest.bPassed cPassFlag = "1" ok
                cSkipFlag = "0"
                if oTest.bSkipped cSkipFlag = "1" ok
                cTodoFlag = "0"
                if oTest.bTodo cTodoFlag = "1" ok
                cXFailFlag = "0"
                if oTest.bXFail cXFailFlag = "1" ok

                cScript += "    [" + '"' + escapeRingString(oTest.cName) + '", ' +
                           cPassFlag + ", " +
                           string(oTest.nDuration) + ', "' +
                           escapeRingString(oTest.cErrorMessage) + '", ' +
                           cSkipFlag + ', "' +
                           escapeRingString(oTest.cSkipReason) + '", ' +
                           cTodoFlag + ", " +
                           cXFailFlag + ']'
                if tIdx < len(aGlobalTestSuites[sIdx].aTests) cScript += "," ok
                cScript += nl
            next
            cScript += "  ]]"
            if sIdx < len(aGlobalTestSuites) cScript += "," ok
            cScript += nl
        next
        cScript += "]" + nl
        writeFileContent(cFilePath, cScript)

    func loadResultsPayload cFilePath
        if !fexists(cFilePath)
            return []
        ok
        cCode = read(cFilePath)
        if cCode = "" or cCode = NULL
            return []
        ok
        aWorkerResults = []
        try
            aWorkerResults = eval(cCode)
        catch
            return []
        done
        if !isList(aWorkerResults)
            return []
        ok

        aParsedSuites = []
        for sIdx = 1 to len(aWorkerResults)
            aSuiteItem = aWorkerResults[sIdx]
            oSuite = new TestSuite(aSuiteItem[1])
            oSuite.nPassCount = aSuiteItem[2]
            oSuite.nFailCount = aSuiteItem[3]
            if len(aSuiteItem) >= 6 and isList(aSuiteItem[6])
                oSuite.nSkipCount = aSuiteItem[4]
                oSuite.nTotalDuration = aSuiteItem[5]
                aTestsList = aSuiteItem[6]
            else
                oSuite.nTotalDuration = aSuiteItem[4]
                aTestsList = aSuiteItem[5]
            ok
            for tIdx = 1 to len(aTestsList)
                aTestItem = aTestsList[tIdx]
                oTest = new TestCase(aTestItem[1], NULL)
                oTest.bPassed = (aTestItem[2] = 1 or aTestItem[2] = "1" or aTestItem[2] = true)
                oTest.nDuration = aTestItem[3]
                oTest.cErrorMessage = aTestItem[4]
                if len(aTestItem) >= 5
                    oTest.bSkipped = (aTestItem[5] = 1 or aTestItem[5] = "1" or aTestItem[5] = true)
                ok
                if len(aTestItem) >= 6
                    oTest.cSkipReason = aTestItem[6]
                ok
                if len(aTestItem) >= 7
                    oTest.bTodo = (aTestItem[7] = 1 or aTestItem[7] = "1" or aTestItem[7] = true)
                ok
                if len(aTestItem) >= 8
                    oTest.bXFail = (aTestItem[8] = 1 or aTestItem[8] = "1" or aTestItem[8] = true)
                ok
                add(oSuite.aTests, oTest)
            next
            add(aParsedSuites, oSuite)
        next
        return aParsedSuites

    func escapeRingString cStr
        cRes = ""
        for i = 1 to len(cStr)
            nCh = ascii(cStr[i])
            if nCh = 34
                cRes += '\"'
            but nCh = 92
                cRes += '\\'
            but nCh = 10
                cRes += '\n'
            but nCh = 13
                # ignore CR
            but nCh = 9
                cRes += '\t'
            else
                cRes += cStr[i]
            ok
        next
        return cRes

    func printResultsPayload
        for sIdx = 1 to len(aGlobalTestSuites)
            ? "[SUITE]"
            ? "name=" + aGlobalTestSuites[sIdx].cName
            ? "passed=" + string(aGlobalTestSuites[sIdx].nPassCount)
            ? "failed=" + string(aGlobalTestSuites[sIdx].nFailCount)
            ? "duration=" + string(aGlobalTestSuites[sIdx].nTotalDuration)
            for tIdx = 1 to len(aGlobalTestSuites[sIdx].aTests)
                oTest = aGlobalTestSuites[sIdx].aTests[tIdx]
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
        aLines = str2list(cPayload)
        aParsedSuites = []
        
        cCurSuiteName = ""
        nCurSuitePass = 0
        nCurSuiteFail = 0
        nCurSuiteDur = 0.0
        aCurSuiteTests = []

        cCurTestName = ""
        bCurTestPassed = false
        nCurTestDur = 0.0
        cCurTestErr = ""
        bInTest = false
        bInSuite = false

        for cLine in aLines
            cLine = cleanLine(cLine)
            if cLine = ""
                loop
            ok
            if cLine = "[SUITE]"
                if bInTest
                    oTest = new TestCase(cCurTestName, NULL)
                    oTest.bPassed = bCurTestPassed
                    oTest.nDuration = nCurTestDur
                    oTest.cErrorMessage = cCurTestErr
                    add(aCurSuiteTests, oTest)
                    bInTest = false
                ok
                if bInSuite
                    oSuite = new TestSuite(cCurSuiteName)
                    oSuite.nPassCount = nCurSuitePass
                    oSuite.nFailCount = nCurSuiteFail
                    oSuite.nTotalDuration = nCurSuiteDur
                    oSuite.aTests = aCurSuiteTests
                    add(aParsedSuites, oSuite)
                ok
                cCurSuiteName = ""
                nCurSuitePass = 0
                nCurSuiteFail = 0
                nCurSuiteDur = 0.0
                aCurSuiteTests = []
                bInSuite = true
            but cLine = "[TEST]"
                if bInTest
                    oTest = new TestCase(cCurTestName, NULL)
                    oTest.bPassed = bCurTestPassed
                    oTest.nDuration = nCurTestDur
                    oTest.cErrorMessage = cCurTestErr
                    add(aCurSuiteTests, oTest)
                ok
                cCurTestName = ""
                bCurTestPassed = false
                nCurTestDur = 0.0
                cCurTestErr = ""
                bInTest = true
            but left(cLine, 5) = "name="
                cVal = cleanLine(substr(cLine, 6, len(cLine) - 5))
                if bInTest
                    cCurTestName = cVal
                else
                    cCurSuiteName = cVal
                ok
            but left(cLine, 7) = "passed="
                cVal = cleanLine(substr(cLine, 8, len(cLine) - 7))
                if bInTest
                    bCurTestPassed = (cVal = "1" or cVal = "true")
                else
                    nCurSuitePass = number(cVal)
                ok
            but left(cLine, 7) = "failed="
                cVal = cleanLine(substr(cLine, 8, len(cLine) - 7))
                nCurSuiteFail = number(cVal)
            but left(cLine, 9) = "duration="
                cVal = cleanLine(substr(cLine, 10, len(cLine) - 9))
                if bInTest
                    nCurTestDur = number(cVal)
                else
                    nCurSuiteDur = number(cVal)
                ok
            but left(cLine, 6) = "error="
                cVal = cleanLine(substr(cLine, 7, len(cLine) - 6))
                if bInTest
                    cCurTestErr = cVal
                ok
            ok
        next

        if bInTest
            oTest = new TestCase(cCurTestName, NULL)
            oTest.bPassed = bCurTestPassed
            oTest.nDuration = nCurTestDur
            oTest.cErrorMessage = cCurTestErr
            add(aCurSuiteTests, oTest)
        ok
        if bInSuite
            oSuite = new TestSuite(cCurSuiteName)
            oSuite.nPassCount = nCurSuitePass
            oSuite.nFailCount = nCurSuiteFail
            oSuite.nTotalDuration = nCurSuiteDur
            oSuite.aTests = aCurSuiteTests
            add(aParsedSuites, oSuite)
        ok

        return aParsedSuites

    func cleanLine cStr
        cTrim = trim(cStr)
        while len(cTrim) > 0
            if right(cTrim, 1) = char(13) or right(cTrim, 1) = char(10)
                cTrim = left(cTrim, len(cTrim) - 1)
            else
                exit
            ok
        end
        return trim(cTrim)

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
        nTotalSkipped = 0

        # Run Global beforeAll hooks
        aGlobalBAll = getGlobalBeforeAll()
        for vHook in aGlobalBAll
            safeCall(vHook, NULL)
        next

        for sIdx = 1 to len(aGlobalTestSuites)
            nSuitesTotal++
            bSuiteSuccess = true
            oReporter.printSuiteHeader(aGlobalTestSuites[sIdx].cName)

            nSuiteStart = clock()

            # Run Suite beforeAll hooks
            for vHook in aGlobalTestSuites[sIdx].aBeforeAll
                safeCall(vHook, aGlobalTestSuites[sIdx])
            next

            for tIdx = 1 to len(aGlobalTestSuites[sIdx].aTests)
                if cFilter != "" and !substr(aGlobalTestSuites[sIdx].aTests[tIdx].cName, cFilter)
                    loop
                ok

                # Suite-level skipAll check
                if aGlobalTestSuites[sIdx].lSkipAll
                    aGlobalTestSuites[sIdx].aTests[tIdx].bSkipped = true
                    if aGlobalTestSuites[sIdx].cSkipReason != ""
                        aGlobalTestSuites[sIdx].aTests[tIdx].cSkipReason = aGlobalTestSuites[sIdx].cSkipReason
                    ok
                ok

                # Skip handling
                if aGlobalTestSuites[sIdx].aTests[tIdx].bSkipped
                    nTotalSkipped++
                    aGlobalTestSuites[sIdx].nSkipCount++
                    oReporter.printTestSkip(aGlobalTestSuites[sIdx].aTests[tIdx])
                    loop
                ok

                nTestStart = clock()

                # Run Global beforeEach hooks
                aGlobalBEach = getGlobalBeforeEach()
                for vHook in aGlobalBEach
                    safeCall(vHook, aGlobalTestSuites[sIdx].aTests[tIdx])
                next

                # Run Suite beforeEach hooks
                for vHook in aGlobalTestSuites[sIdx].aBeforeEach
                    safeCall(vHook, aGlobalTestSuites[sIdx].aTests[tIdx])
                next

                # Run test body safely
                try
                    if !isNull(aGlobalTestSuites[sIdx].aTests[tIdx].vCallback)
                        safeCallTest(aGlobalTestSuites[sIdx].aTests[tIdx].vCallback, aGlobalTestSuites[sIdx].aTests[tIdx].aParams, aGlobalTestSuites[sIdx].aTests[tIdx])
                    ok
                    aGlobalTestSuites[sIdx].aTests[tIdx].bPassed = true
                    aGlobalTestSuites[sIdx].aTests[tIdx].nDuration = (clock() - nTestStart) / clockspersecond()
                    nTotalPassed++
                    aGlobalTestSuites[sIdx].nPassCount++
                    oReporter.printTestPass(aGlobalTestSuites[sIdx].aTests[tIdx])
                catch
                    if aGlobalTestSuites[sIdx].aTests[tIdx].bXFail
                        # Expected failure!
                        aGlobalTestSuites[sIdx].aTests[tIdx].bPassed = true
                        aGlobalTestSuites[sIdx].aTests[tIdx].cErrorMessage = "(Expected Failure) " + cCatchError
                        aGlobalTestSuites[sIdx].aTests[tIdx].nDuration = (clock() - nTestStart) / clockspersecond()
                        nTotalPassed++
                        aGlobalTestSuites[sIdx].nPassCount++
                        oReporter.printTestPass(aGlobalTestSuites[sIdx].aTests[tIdx])
                    else
                        aGlobalTestSuites[sIdx].aTests[tIdx].bPassed = false
                        aGlobalTestSuites[sIdx].aTests[tIdx].cErrorMessage = cCatchError
                        aGlobalTestSuites[sIdx].aTests[tIdx].nDuration = (clock() - nTestStart) / clockspersecond()
                        nTotalFailed++
                        aGlobalTestSuites[sIdx].nFailCount++
                        bSuiteSuccess = false
                        oReporter.printTestFail(aGlobalTestSuites[sIdx].aTests[tIdx])
                    ok
                done

                # Run Suite afterEach hooks
                for vHook in aGlobalTestSuites[sIdx].aAfterEach
                    safeCall(vHook, aGlobalTestSuites[sIdx].aTests[tIdx])
                next

                # Run Global afterEach hooks
                aGlobalAEach = getGlobalAfterEach()
                for vHook in aGlobalAEach
                    safeCall(vHook, aGlobalTestSuites[sIdx].aTests[tIdx])
                next
            next

            # Run Suite afterAll hooks
            for vHook in aGlobalTestSuites[sIdx].aAfterAll
                safeCall(vHook, aGlobalTestSuites[sIdx])
            next

            aGlobalTestSuites[sIdx].nTotalDuration = (clock() - nSuiteStart) / clockspersecond()

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

        # Run Global beforeAll hooks
        aGlobalBAll = getGlobalBeforeAll()
        for vHook in aGlobalBAll
            safeCall(vHook, NULL)
        next

        for sIdx = 1 to len(aGlobalTestSuites)
            nSuitesTotal++
            bSuiteSuccess = true
            oReporter.printSuiteHeader(aGlobalTestSuites[sIdx].cName)

            nSuiteStart = clock()

            # Run Suite beforeAll hooks
            for vHook in aGlobalTestSuites[sIdx].aBeforeAll
                safeCall(vHook, aGlobalTestSuites[sIdx])
            next

            for tIdx = 1 to len(aGlobalTestSuites[sIdx].aTests)
                if cFilter != "" and !substr(aGlobalTestSuites[sIdx].aTests[tIdx].cName, cFilter)
                    loop
                ok

                # Suite-level skipAll check
                if aGlobalTestSuites[sIdx].lSkipAll
                    aGlobalTestSuites[sIdx].aTests[tIdx].bSkipped = true
                    if aGlobalTestSuites[sIdx].cSkipReason != ""
                        aGlobalTestSuites[sIdx].aTests[tIdx].cSkipReason = aGlobalTestSuites[sIdx].cSkipReason
                    ok
                ok

                # Skip handling
                if aGlobalTestSuites[sIdx].aTests[tIdx].bSkipped
                    nTotalSkipped++
                    aGlobalTestSuites[sIdx].nSkipCount++
                    oReporter.printTestSkip(aGlobalTestSuites[sIdx].aTests[tIdx])
                    loop
                ok

                nTestStart = clock()

                # Run Global beforeEach hooks
                aGlobalBEach = getGlobalBeforeEach()
                for vHook in aGlobalBEach
                    safeCall(vHook, aGlobalTestSuites[sIdx].aTests[tIdx])
                next

                # Run Suite beforeEach hooks
                for vHook in aGlobalTestSuites[sIdx].aBeforeEach
                    safeCall(vHook, aGlobalTestSuites[sIdx].aTests[tIdx])
                next

                # Run test body safely
                try
                    if !isNull(aGlobalTestSuites[sIdx].aTests[tIdx].vCallback)
                        safeCallTest(aGlobalTestSuites[sIdx].aTests[tIdx].vCallback, aGlobalTestSuites[sIdx].aTests[tIdx].aParams, aGlobalTestSuites[sIdx].aTests[tIdx])
                    ok
                    aGlobalTestSuites[sIdx].aTests[tIdx].bPassed = true
                    aGlobalTestSuites[sIdx].aTests[tIdx].nDuration = (clock() - nTestStart) / clockspersecond()
                    nTotalPassed++
                    aGlobalTestSuites[sIdx].nPassCount++
                    oReporter.printTestPass(aGlobalTestSuites[sIdx].aTests[tIdx])
                catch
                    if aGlobalTestSuites[sIdx].aTests[tIdx].bXFail
                        # Expected failure!
                        aGlobalTestSuites[sIdx].aTests[tIdx].bPassed = true
                        aGlobalTestSuites[sIdx].aTests[tIdx].cErrorMessage = "(Expected Failure) " + cCatchError
                        aGlobalTestSuites[sIdx].aTests[tIdx].nDuration = (clock() - nTestStart) / clockspersecond()
                        nTotalPassed++
                        aGlobalTestSuites[sIdx].nPassCount++
                        oReporter.printTestPass(aGlobalTestSuites[sIdx].aTests[tIdx])
                    else
                        aGlobalTestSuites[sIdx].aTests[tIdx].bPassed = false
                        aGlobalTestSuites[sIdx].aTests[tIdx].cErrorMessage = cCatchError
                        aGlobalTestSuites[sIdx].aTests[tIdx].nDuration = (clock() - nTestStart) / clockspersecond()
                        nTotalFailed++
                        aGlobalTestSuites[sIdx].nFailCount++
                        bSuiteSuccess = false
                        oReporter.printTestFail(aGlobalTestSuites[sIdx].aTests[tIdx])
                    ok
                done

                # Run Suite afterEach hooks
                for vHook in aGlobalTestSuites[sIdx].aAfterEach
                    safeCall(vHook, aGlobalTestSuites[sIdx].aTests[tIdx])
                next

                # Run Global afterEach hooks
                aGlobalAEach = getGlobalAfterEach()
                for vHook in aGlobalAEach
                    safeCall(vHook, aGlobalTestSuites[sIdx].aTests[tIdx])
                next
            next

            # Run Suite afterAll hooks
            for vHook in aGlobalTestSuites[sIdx].aAfterAll
                safeCall(vHook, aGlobalTestSuites[sIdx])
            next

            aGlobalTestSuites[sIdx].nTotalDuration = (clock() - nSuiteStart) / clockspersecond()

            if bSuiteSuccess
                nSuitesPassed++
            ok
            add(aAllSuites, aGlobalTestSuites[sIdx])
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
        nTotalSkipped = 0
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
            oReporter.printJSON(nSuitesPassed, nSuitesTotal, nTotalPassed, nTotalFailed, nTotalTime, nTotalSkipped)
        else
            oReporter.printSummary(nSuitesPassed, nSuitesTotal, nTotalPassed, nTotalFailed, nTotalTime, nTotalSkipped)
        ok

        # Generate HTML report if requested
        if oParser != NULL and oParser.bHtmlReport
            cHtmlPath = resolveReportPath(oParser.cHtmlReportPath, "test-report.html")
            oReporter.generateHtmlReport(aAllSuites, cHtmlPath, nSuitesPassed, nSuitesTotal, nTotalPassed, nTotalFailed, nTotalTime, nTotalSkipped)
        ok

        # Generate JUnit XML report if requested
        if oParser != NULL and oParser.bJunitReport
            cJunitPath = resolveReportPath(oParser.cJunitReportPath, "test-report.xml")
            oReporter.generateJunitReport(aAllSuites, cJunitPath, nSuitesPassed, nSuitesTotal, nTotalPassed, nTotalFailed, nTotalTime, nTotalSkipped)
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
        nTotalSkipped = 0
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
                nTotalSkipped = 0
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

    func safeCallTest vFunc, aParams, oArg
        if isNull(vFunc) return ok
        if isList(aParams) and len(aParams) > 0
            nLen = len(aParams)
            if nLen = 1
                call vFunc(aParams[1])
            but nLen = 2
                call vFunc(aParams[1], aParams[2])
            but nLen = 3
                call vFunc(aParams[1], aParams[2], aParams[3])
            but nLen = 4
                call vFunc(aParams[1], aParams[2], aParams[3], aParams[4])
            but nLen = 5
                call vFunc(aParams[1], aParams[2], aParams[3], aParams[4], aParams[5])
            else
                call vFunc(aParams)
            ok
            return
        ok
        safeCall(vFunc, oArg)

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
        if cPath = "" or cPath = NULL
            cPath = "."
        ok
        cPath = substr(cPath, char(92), "/")

        aEntries = []
        try
            aEntries = dir(cPath)
        catch
            return
        done

        if !isList(aEntries)
            return
        ok

        for entry in aEntries
            cName = entry[1]
            bIsDir = entry[2]

            if cName = "." or cName = ".."
                loop
            ok

            cFullPath = cPath
            if right(cFullPath, 1) != "/"
                cFullPath += "/"
            ok
            cFullPath += cName
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