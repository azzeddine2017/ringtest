# src/core/reporter.ring

class TestReporter
    cReset  = ""
    cBold   = ""
    cRed    = ""
    cGreen  = ""
    cYellow = ""
    cCyan   = ""
    cGray   = ""

    func init
        cReset  = char(27) + "[0m"
        cBold   = char(27) + "[1m"
        cRed    = char(27) + "[31m"
        cGreen  = char(27) + "[32m"
        cYellow = char(27) + "[33m"
        cCyan   = char(27) + "[36m"
        cGray   = char(27) + "[90m"
        return self

    func printHeader cFile
        ? cBold + cCyan + " RUNS " + cReset + " " + cGray + cFile + cReset
        ? ""

    func printSuiteHeader cSuiteName
        ? cBold + cSuiteName + cReset

    func printTestPass oTest
        cTimeStr = "(" + string(floor(oTest.nDuration * 1000)) + " ms)"
        ? "  " + cGreen + "✓" + cReset + " " + cGray + oTest.cName + " " + cTimeStr + cReset

    func printTestFail oTest
        cTimeStr = "(" + string(floor(oTest.nDuration * 1000)) + " ms)"
        ? "  " + cRed + "✗ " + oTest.cName + " " + cTimeStr + cReset
        ? "    " + cRed + cBold + "Error: " + cReset + cRed + oTest.cErrorMessage + cReset
        
        # Explain common Ring errors with clear actionable tips
        cHint = explainRingError(oTest.cErrorMessage)
        if cHint != ""
            ? "    " + cYellow + "💡 Tip: " + cReset + cGray + cHint + cReset
        ok

        # Show diff if error message contains expected/received values
        if substr(oTest.cErrorMessage, "Expected [")
            showDiff(oTest.cErrorMessage)
        ok

    func printLoadError cFilePath, cErrorMsg, cDependency
        ? ""
        ? cRed + cBold + "✖ Test File / Dependency Load Failure" + cReset
        ? "  " + cBold + "Target:     " + cReset + cGray + cFilePath + cReset
        if cDependency != ""
            ? "  " + cBold + "Dependency: " + cReset + cYellow + cDependency + cReset
        ok
        ? "  " + cBold + "Reason:     " + cReset + cRed + cErrorMsg + cReset
        
        cHint = explainRingError(cErrorMsg)
        if cHint != ""
            ? "  " + cBold + "💡 Diagnosis: " + cReset + cCyan + cHint + cReset
        ok
        ? ""

    func explainRingError cErrorMsg
        if substr(cErrorMsg, "Error (R19)") > 0 or substr(cErrorMsg, "less number of parameters") > 0
            return "Function called with fewer parameters than declared (e.g. calling substr(str, start) with 2 arguments when Ring requires 3: substr(str, start, len))."
        but substr(cErrorMsg, "Error (R20)") > 0 or substr(cErrorMsg, "extra number of parameters") > 0
            return "Function called with more parameters than declared (e.g. passing arguments to a 0-parameter function or callback)."
        but substr(cErrorMsg, "Error (R24)") > 0 or substr(cErrorMsg, "uninitialized variable") > 0
            return "Accessing an uninitialized or out-of-scope variable. Check variable spelling, scope, or global declaration."
        but substr(cErrorMsg, "Error (R50)") > 0 or substr(cErrorMsg, "operator overloading") > 0
            return "Object does not support the requested operation or operator. Check object type."
        but substr(cErrorMsg, "Error (C22)") > 0 or substr(cErrorMsg, "Function redefinition") > 0
            return "Function name collision: A function with the same name was already declared in another loaded file."
        but substr(cErrorMsg, "Error (E9)") > 0 or substr(cErrorMsg, "Can't open file") > 0
            return "File could not be found or opened. Check the relative path and working directory."
        but substr(cErrorMsg, "Error (C27)") > 0 or substr(cErrorMsg, "Syntax Error") > 0
            return "Syntax error in Ring source code. Check parentheses, strings, or block termination (ok/end)."
        ok
        return ""

    func showDiff cErrorMsg
        ? "    " + cGray + "--- Diff ---" + cReset
        showOneValue(cErrorMsg, "Expected [", cGreen, "Expected")
        showOneValue(cErrorMsg, "received [", cRed, "Received")

    func showOneValue cMsg, cMarker, cColor, cLabel
        nStart = substr(cMsg, cMarker)
        if nStart = 0
            return
        ok
        nValueStart = nStart + len(cMarker)
        cTail = substr(cMsg, nValueStart, len(cMsg))
        nEnd = substr(cTail, "]")
        if nEnd = 0
            return
        ok
        cValue = substr(cTail, 1, nEnd - 1)
        ? "    " + cColor + cLabel + ": " + cReset + cValue

    func printSummary nSuitesPassed, nSuitesTotal, nTestsPassed, nTestsFailed, nTotalTime
        ? ""
        ? cGray + "--------------------------------------------------" + cReset
        
        cSuiteStats = string(nSuitesPassed) + " passed, " + string(nSuitesTotal) + " total"
        ? cBold + "Test Suites: " + cReset + cSuiteStats
        
        cTestStats = ""
        if nTestsFailed > 0
            cTestStats = cRed + string(nTestsFailed) + " failed" + cReset + ", "
        ok
        cTestStats += cGreen + string(nTestsPassed) + " passed" + cReset + ", " + string(nTestsPassed + nTestsFailed) + " total"
        ? cBold + "Tests:       " + cReset + cTestStats

        ? cBold + "Time:        " + cReset + string(nTotalTime) + " s"
        ? cGray + "--------------------------------------------------" + cReset

        if nTestsFailed = 0
            ? cGreen + cBold + "STATUS: ALL TESTS PASSED!" + cReset
        else
            ? cRed + cBold + "STATUS: SOME TESTS FAILED!" + cReset
        ok
        ? ""

    func printJSON nSuitesPassed, nSuitesTotal, nTestsPassed, nTestsFailed, nTotalTime
        ? "{"
        ? '  "suites": {'
        ? '    "passed": ' + string(nSuitesPassed) + ","
        ? '    "total": ' + string(nSuitesTotal)
        ? "  },"
        ? '  "tests": {'
        ? '    "passed": ' + string(nTestsPassed) + ","
        ? '    "failed": ' + string(nTestsFailed) + ","
        ? '    "total": ' + string(nTestsPassed + nTestsFailed)
        ? "  },"
        ? '  "time": ' + string(nTotalTime)
        ? "}"