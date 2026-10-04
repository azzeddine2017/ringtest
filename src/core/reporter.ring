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
        ? "  " + cGreen + iif(isWindows(),"[PASS] ", "✓ ") + cReset + " " + cGray + oTest.cName + " " + cTimeStr + cReset

    func printTestFail oTest
        cTimeStr = "(" + string(floor(oTest.nDuration * 1000)) + " ms)"
        ? "  " + cRed + iif(isWindows(),"[FAIL] ", "✗ ") + oTest.cName + " " + cTimeStr + cReset
        ? "    " + cRed + cBold + "Error: " + cReset + cRed + oTest.cErrorMessage + cReset
        
        # Explain common Ring errors with clear actionable tips
        cHint = explainRingError(oTest.cErrorMessage)
        if cHint != ""
            ? "    " + cYellow + iif(isWindows(),"[Tip] ","💡 Tip:") + cReset + cGray + cHint + cReset
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
            ? "  " + cBold + iif(isWindows(),"[Diagnosis] ","💡 Diagnosis: ") + cReset + cCyan + cHint + cReset
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
        cTail = substr(cMsg, nValueStart, len(cMsg) - nValueStart + 1)
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

    func generateHtmlReport aSuites, cFilePath, nSuitesPassed, nSuitesTotal, nTestsPassed, nTestsFailed, nTotalTime
        cStatus = "PASSED"
        cStatusClass = "badge-pass"
        if nTestsFailed > 0
            cStatus = "FAILED"
            cStatusClass = "badge-fail"
        ok

        nPassPercent = 100
        nTotalTests = nTestsPassed + nTestsFailed
        if nTotalTests > 0
            nPassPercent = floor((nTestsPassed / nTotalTests) * 100)
        ok

        cTimeStr = string(floor(nTotalTime * 1000)) + " ms"
        if nTotalTime >= 1.0
            cTimeStr = string(nTotalTime) + " s"
        ok

        # Build suites HTML
        cSuitesHtml = ""
        for sIdx = 1 to len(aSuites)
            oSuite = aSuites[sIdx]
            cSuiteStatus = "pass"
            cSuiteBadge = "badge-pass"
            if oSuite.nFailCount > 0
                cSuiteStatus = "fail"
                cSuiteBadge = "badge-fail"
            ok

            cSuiteTime = string(floor(oSuite.nTotalDuration * 1000)) + " ms"

            cTestsHtml = ""
            for tIdx = 1 to len(oSuite.aTests)
                oTest = oSuite.aTests[tIdx]
                cTestStatus = "pass"
                cTestIcon = "✓"
                cTestIconClass = "icon-pass"
                cErrHtml = ""
                if !oTest.bPassed
                    cTestStatus = "fail"
                    cTestIcon = "✗"
                    cTestIconClass = "icon-fail"
                    cEscErr = escapeHtml(oTest.cErrorMessage)
                    cTip = explainRingError(oTest.cErrorMessage)
                    cTipHtml = ""
                    if cTip != ""
                        cTipHtml = '<div class="tip-box"><strong>💡 Tip:</strong> ' + escapeHtml(cTip) + '</div>'
                    ok
                    cErrHtml = '<div class="test-error">' +
                               '  <div class="error-msg">' + cEscErr + '</div>' +
                                  cTipHtml +
                               '</div>'
                ok

                cTestDuration = string(floor(oTest.nDuration * 1000)) + " ms"

                cTestsHtml += '<div class="test-item test-' + cTestStatus + '" data-status="' + cTestStatus + '">' +
                              '  <div class="test-item-header">' +
                              '    <span class="test-icon ' + cTestIconClass + '">' + cTestIcon + '</span>' +
                              '    <span class="test-name">' + escapeHtml(oTest.cName) + '</span>' +
                              '    <span class="test-time">' + cTestDuration + '</span>' +
                              '  </div>' +
                              cErrHtml +
                              '</div>'
            next

            cSuitesHtml += '<div class="suite-card suite-' + cSuiteStatus + '" data-status="' + cSuiteStatus + '">' +
                           '  <div class="suite-header" onclick="toggleSuite(' + string(sIdx) + ')">' +
                           '    <div class="suite-title">' +
                           '      <span class="chevron" id="chevron-' + string(sIdx) + '">▼</span>' +
                           '      <strong>' + escapeHtml(oSuite.cName) + '</strong>' +
                           '    </div>' +
                           '    <div class="suite-meta">' +
                           '      <span class="badge ' + cSuiteBadge + '">' + string(oSuite.nPassCount) + '/' + string(len(oSuite.aTests)) + ' passed</span>' +
                           '      <span class="suite-time">' + cSuiteTime + '</span>' +
                           '    </div>' +
                           '  </div>' +
                           '  <div class="suite-body" id="suite-body-' + string(sIdx) + '">' +
                           cTestsHtml +
                           '  </div>' +
                           '</div>'
        next

        # Full HTML Document
        cHtml = '<!DOCTYPE html>' + nl +
                '<html lang="en">' + nl +
                '<head>' + nl +
                '  <meta charset="UTF-8">' + nl +
                '  <meta name="viewport" content="width=device-width, initial-scale=1.0">' + nl +
                '  <title>RingTest Report</title>' + nl +
                '  <style>' + nl +
                '    :root {' + nl +
                '      --bg: #0f172a; --card: #1e293b; --border: #334155;' + nl +
                '      --text: #f8fafc; --text-muted: #94a3b8;' + nl +
                '      --pass: #10b981; --pass-bg: rgba(16, 185, 129, 0.12);' + nl +
                '      --fail: #ef4444; --fail-bg: rgba(239, 68, 68, 0.12);' + nl +
                '      --accent: #38bdf8; --tip-bg: rgba(56, 189, 248, 0.1);' + nl +
                '    }' + nl +
                '    * { box-sizing: border-box; margin: 0; padding: 0; }' + nl +
                '    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: var(--bg); color: var(--text); padding: 32px 20px; }' + nl +
                '    .container { max-width: 1000px; margin: 0 auto; }' + nl +
                '    header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; padding-bottom: 20px; border-bottom: 1px solid var(--border); }' + nl +
                '    .brand { display: flex; align-items: center; gap: 12px; }' + nl +
                '    .logo { width: 36px; height: 36px; background: linear-gradient(135deg, #38bdf8, #818cf8); border-radius: 8px; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 20px; color: #0f172a; }' + nl +
                '    h1 { font-size: 24px; font-weight: 700; letter-spacing: -0.5px; }' + nl +
                '    .badge { padding: 4px 12px; border-radius: 9999px; font-size: 13px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px; }' + nl +
                '    .badge-pass { background: var(--pass-bg); color: var(--pass); border: 1px solid var(--pass); }' + nl +
                '    .badge-fail { background: var(--fail-bg); color: var(--fail); border: 1px solid var(--fail); }' + nl +
                '    .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 16px; margin-bottom: 28px; }' + nl +
                '    .stat-card { background: var(--card); border: 1px solid var(--border); border-radius: 12px; padding: 18px; }' + nl +
                '    .stat-label { color: var(--text-muted); font-size: 13px; font-weight: 500; margin-bottom: 6px; }' + nl +
                '    .stat-val { font-size: 28px; font-weight: 700; }' + nl +
                '    .progress-bar { width: 100%; height: 6px; background: var(--border); border-radius: 9999px; margin-top: 8px; overflow: hidden; }' + nl +
                '    .progress-fill { height: 100%; background: var(--pass); border-radius: 9999px; }' + nl +
                '    .controls { display: flex; gap: 12px; margin-bottom: 20px; flex-wrap: wrap; }' + nl +
                '    .search-box { flex: 1; min-width: 250px; position: relative; }' + nl +
                '    .search-box input { width: 100%; padding: 10px 14px; background: var(--card); border: 1px solid var(--border); border-radius: 8px; color: var(--text); font-size: 14px; outline: none; transition: border-color 0.2s; }' + nl +
                '    .search-box input:focus { border-color: var(--accent); }' + nl +
                '    .filter-btn { padding: 8px 16px; background: var(--card); border: 1px solid var(--border); border-radius: 8px; color: var(--text-muted); font-size: 13px; font-weight: 600; cursor: pointer; transition: all 0.2s; }' + nl +
                '    .filter-btn.active, .filter-btn:hover { background: var(--border); color: var(--text); }' + nl +
                '    .suite-card { background: var(--card); border: 1px solid var(--border); border-radius: 10px; margin-bottom: 14px; overflow: hidden; }' + nl +
                '    .suite-header { padding: 14px 18px; display: flex; justify-content: space-between; align-items: center; cursor: pointer; user-select: none; background: rgba(255,255,255,0.02); }' + nl +
                '    .suite-header:hover { background: rgba(255,255,255,0.04); }' + nl +
                '    .suite-title { display: flex; align-items: center; gap: 10px; font-size: 15px; }' + nl +
                '    .chevron { font-size: 11px; color: var(--text-muted); transition: transform 0.2s; }' + nl +
                '    .chevron.collapsed { transform: rotate(-90deg); }' + nl +
                '    .suite-meta { display: flex; align-items: center; gap: 12px; }' + nl +
                '    .suite-time, .test-time { font-size: 12px; color: var(--text-muted); font-family: monospace; }' + nl +
                '    .suite-body { border-top: 1px solid var(--border); }' + nl +
                '    .suite-body.hidden { display: none; }' + nl +
                '    .test-item { padding: 12px 18px; border-bottom: 1px solid rgba(255,255,255,0.05); }' + nl +
                '    .test-item:last-child { border-bottom: none; }' + nl +
                '    .test-item-header { display: flex; align-items: center; gap: 10px; }' + nl +
                '    .test-icon { font-weight: bold; width: 18px; text-align: center; }' + nl +
                '    .icon-pass { color: var(--pass); }' + nl +
                '    .icon-fail { color: var(--fail); }' + nl +
                '    .test-name { flex: 1; font-size: 14px; }' + nl +
                '    .test-error { margin-top: 10px; padding: 12px; background: rgba(239, 68, 68, 0.08); border-left: 3px solid var(--fail); border-radius: 4px; font-size: 13px; }' + nl +
                '    .error-msg { font-family: monospace; color: #fca5a5; white-space: pre-wrap; word-break: break-all; }' + nl +
                '    .tip-box { margin-top: 8px; padding: 8px 10px; background: var(--tip-bg); border-left: 3px solid var(--accent); color: #bae6fd; font-size: 12px; border-radius: 4px; }' + nl +
                '    footer { margin-top: 40px; text-align: center; color: var(--text-muted); font-size: 13px; }' + nl +
                '  </style>' + nl +
                '</head>' + nl +
                '<body>' + nl +
                '  <div class="container">' + nl +
                '    <header>' + nl +
                '      <div class="brand">' + nl +
                '        <div class="logo">R</div>' + nl +
                '        <div>' + nl +
                '          <h1>RingTest Execution Report</h1>' + nl +
                '        </div>' + nl +
                '      </div>' + nl +
                '      <span class="badge ' + cStatusClass + '">' + cStatus + '</span>' + nl +
                '    </header>' + nl +
                '    <div class="stats-grid">' + nl +
                '      <div class="stat-card">' + nl +
                '        <div class="stat-label">Suites</div>' + nl +
                '        <div class="stat-val">' + string(nSuitesPassed) + ' / ' + string(nSuitesTotal) + '</div>' + nl +
                '      </div>' + nl +
                '      <div class="stat-card">' + nl +
                '        <div class="stat-label">Tests Passed / Total</div>' + nl +
                '        <div class="stat-val" style="color: ' + iif(nTestsFailed > 0 , '#ef4444' , '#10b981') + ';">' + string(nTestsPassed) + ' / ' + string(nTotalTests) + '</div>' + nl +
                '      </div>' + nl +
                '      <div class="stat-card">' + nl +
                '        <div class="stat-label">Success Rate</div>' + nl +
                '        <div class="stat-val">' + string(nPassPercent) + '%</div>' + nl +
                '        <div class="progress-bar"><div class="progress-fill" style="width: ' + string(nPassPercent) + '%;"></div></div>' + nl +
                '      </div>' + nl +
                '      <div class="stat-card">' + nl +
                '        <div class="stat-label">Execution Time</div>' + nl +
                '        <div class="stat-val">' + cTimeStr + '</div>' + nl +
                '      </div>' + nl +
                '    </div>' + nl +
                '    <div class="controls">' + nl +
                '      <div class="search-box">' + nl +
                '        <input type="text" id="searchInput" placeholder="Search test cases or suites..." oninput="applyFilter()">' + nl +
                '      </div>' + nl +
                '      <button class="filter-btn active" id="btn-all" onclick="setTab(\x27all\x27)">All (' + string(nTotalTests) + ')</button>' + nl +
                '      <button class="filter-btn" id="btn-pass" onclick="setTab(\x27pass\x27)">Passed (' + string(nTestsPassed) + ')</button>' + nl +
                '      <button class="filter-btn" id="btn-fail" onclick="setTab(\x27fail\x27)">Failed (' + string(nTestsFailed) + ')</button>' + nl +
                '    </div>' + nl +
                '    <div id="suitesList">' + nl +
                cSuitesHtml +
                '    </div>' + nl +
                '    <footer>' + nl +
                '      Generated by <strong>RingTest</strong> &bull; Modern Test Runner for Ring' + nl +
                '    </footer>' + nl +
                '  </div>' + nl +
                '  <script>' + nl +
                '    let currentTab = "all";' + nl +
                '    function toggleSuite(idx) {' + nl +
                '      const body = document.getElementById("suite-body-" + idx);' + nl +
                '      const chevron = document.getElementById("chevron-" + idx);' + nl +
                '      body.classList.toggle("hidden");' + nl +
                '      chevron.classList.toggle("collapsed");' + nl +
                '    }' + nl +
                '    function setTab(tab) {' + nl +
                '      currentTab = tab;' + nl +
                '      document.querySelectorAll(".filter-btn").forEach(b => b.classList.remove("active"));' + nl +
                '      document.getElementById("btn-" + tab).classList.add("active");' + nl +
                '      applyFilter();' + nl +
                '    }' + nl +
                '    function applyFilter() {' + nl +
                '      const q = document.getElementById("searchInput").value.toLowerCase();' + nl +
                '      document.querySelectorAll(".suite-card").forEach(suite => {' + nl +
                '        let suiteMatch = false;' + nl +
                '        const tests = suite.querySelectorAll(".test-item");' + nl +
                '        tests.forEach(test => {' + nl +
                '          const status = test.getAttribute("data-status");' + nl +
                '          const text = test.innerText.toLowerCase();' + nl +
                '          const tabMatch = (currentTab === "all" || status === currentTab);' + nl +
                '          const searchMatch = (q === "" || text.includes(q) || suite.innerText.toLowerCase().includes(q));' + nl +
                '          if (tabMatch && searchMatch) {' + nl +
                '            test.style.display = "";' + nl +
                '            suiteMatch = true;' + nl +
                '          } else {' + nl +
                '            test.style.display = "none";' + nl +
                '          }' + nl +
                '        });' + nl +
                '        suite.style.display = suiteMatch ? "" : "none";' + nl +
                '      });' + nl +
                '    }' + nl +
                '  </script>' + nl +
                '</body>' + nl +
                '</html>'

        writeFileContent(cFilePath, cHtml)
        ? cGreen + "✔ HTML Report generated: " + cReset + cGray + cFilePath + cReset

    func generateJunitReport aSuites, cFilePath, nSuitesPassed, nSuitesTotal, nTestsPassed, nTestsFailed, nTotalTime
        nTotalTests = nTestsPassed + nTestsFailed

        cXml = '<?xml version="1.0" encoding="UTF-8"?>' + nl +
               '<testsuites name="RingTest" tests="' + string(nTotalTests) + '" failures="' + string(nTestsFailed) + '" errors="0" time="' + string(nTotalTime) + '">' + nl

        for oSuite in aSuites
            cSuiteNameEsc = escapeXml(oSuite.cName)
            cXml += '  <testsuite name="' + cSuiteNameEsc + '" tests="' + string(len(oSuite.aTests)) + '" failures="' + string(oSuite.nFailCount) + '" errors="0" time="' + string(oSuite.nTotalDuration) + '">' + nl
            for oTest in oSuite.aTests
                cTestNameEsc = escapeXml(oTest.cName)
                if oTest.bPassed
                    cXml += '    <testcase name="' + cTestNameEsc + '" classname="' + cSuiteNameEsc + '" time="' + string(oTest.nDuration) + '"/>' + nl
                else
                    cErrMsgEsc = escapeXml(oTest.cErrorMessage)
                    cXml += '    <testcase name="' + cTestNameEsc + '" classname="' + cSuiteNameEsc + '" time="' + string(oTest.nDuration) + '">' + nl +
                            '      <failure message="' + cErrMsgEsc + '" type="AssertionError">' + cErrMsgEsc + '</failure>' + nl +
                            '    </testcase>' + nl
                ok
            next
            cXml += '  </testsuite>' + nl
        next

        cXml += '</testsuites>' + nl

        writeFileContent(cFilePath, cXml)
        ? cGreen + "✔ JUnit XML Report generated: " + cReset + cGray + cFilePath + cReset

    private

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

    func escapeHtml cStr
        if cStr = "" or cStr = NULL
            return ""
        ok
        cRes = string(cStr)
        cRes = substr(cRes, "&", "&amp;")
        cRes = substr(cRes, "<", "&lt;")
        cRes = substr(cRes, ">", "&gt;")
        cRes = substr(cRes, '"', "&quot;")
        return cRes

    func escapeXml cStr
        if cStr = "" or cStr = NULL
            return ""
        ok
        cRes = string(cStr)
        cRes = substr(cRes, "&", "&amp;")
        cRes = substr(cRes, "<", "&lt;")
        cRes = substr(cRes, ">", "&gt;")
        cRes = substr(cRes, '"', "&quot;")
        cRes = substr(cRes, "'", "&apos;")
        return cRes

    func iif bCondition, aTrue, aFalse 
        if bCondition return aTrue ok
        return aFalse