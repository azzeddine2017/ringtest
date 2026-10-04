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

            # Create a unique temp runner script
            cTempScript = cProjectDir + "/.ringtest_worker_" + string(random(999999)) + ".ring"
            cTempScript = substr(cTempScript, char(92), "/")

            cFilterEsc = cFilter
            cCode = 'load "stdlibcore.ring"' + nl +
                    'load "' + cRingTestSrc + '"' + nl +
                    cTestContent + nl + nl +
                    'func main' + nl +
                    '    runner = new TestRunner()' + nl +
                    '    runner.setFilter("' + cFilterEsc + '")' + nl +
                    '    bSuccess = runner.runExecutedSuites("' + cFilePath + '")' + nl +
                    '    if !bSuccess' + nl +
                    '        shutdown(1)' + nl +
                    '    ok' + nl

            write(cTempScript, cCode)

            oReporter.printHeader(cFilePath)

            cOutFile = cProjectDir + "/.ringtest_out_" + string(random(999999)) + ".log"
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

            # Clean up temp runner script
            try
                remove(cTempScript)
            catch
            done

            if cOutput != ""
                see cOutput
            ok

            nSuitesTotal++
            if nCode = 0
                nSuitesPassed++
                nTotalPassed++
                return true
            else
                nTotalFailed++
                return false
            ok
        else
            return runFileDirect(cFilePath, cProjectDir)
        ok

    func runExecutedSuites cFilePath
        nStartTime = clock()

        nSuitesTotal = 0
        nTotalPassed = 0
        nTotalFailed = 0

        aSuites = getGlobalSuites()
        for oSuite in aSuites
            nSuitesTotal++
            bSuiteSuccess = true
            oReporter.printSuiteHeader(oSuite.cName)

            for oTest in oSuite.aTests
                if cFilter != "" and !substr(oTest.cName, cFilter)
                    loop
                ok

                nTestStart = clock()

                # Run beforeEach hooks safely
                aBeforeEach = getGlobalBeforeEach()
                for vHook in aBeforeEach
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

                # Run afterEach hooks safely
                aAfterEach = getGlobalAfterEach()
                for vHook in aAfterEach
                    safeCall(vHook, oTest)
                next
            next

            if bSuiteSuccess
                nSuitesPassed++
            ok
            ? ""
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
        for oSuite in aSuites
            nSuitesTotal++
            bSuiteSuccess = true
            oReporter.printSuiteHeader(oSuite.cName)

            for oTest in oSuite.aTests
                if cFilter != "" and !substr(oTest.cName, cFilter)
                    loop
                ok

                nTestStart = clock()

                # Run beforeEach hooks safely
                aBeforeEach = getGlobalBeforeEach()
                for vHook in aBeforeEach
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

                # Run afterEach hooks safely
                aAfterEach = getGlobalAfterEach()
                for vHook in aAfterEach
                    safeCall(vHook, oTest)
                next
            next

            if bSuiteSuccess
                nSuitesPassed++
            ok
            ? ""
        next

        try
            chdir(cOrigDir)
        catch
        done

        return (nTotalFailed = 0)

    func runAll
        nGlobalStart = clock()

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
                # Fixed: pass 3 parameters to substr (string, start, length)
                cRest = substr(cTrim, nStart + 1, len(cTrim))
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