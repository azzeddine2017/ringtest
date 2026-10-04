# src/cli/args_parser.ring
 
class ArgsParser
    cCallerDir = sysget("RINGTEST_CALLER_DIR")
    cTargetDirectory = "."
    cTargetFile = ""
    bShowHelp = false
    bShowVersion = false
    cFilter = ""
    bWatchMode = false
    bParallel = false
    bJsonOutput = false
    bHtmlReport = false
    cHtmlReportPath = ""
    bJunitReport = false
    cJunitReportPath = ""

    func parse aArgs
        if cCallerDir != NULL and cCallerDir != ""
            cTargetDirectory = cCallerDir
        else
            cTargetDirectory = "."
        ok
        cTargetDirectory = substr(cTargetDirectory, char(92), "/")

        nLen = len(aArgs)
        if nLen = 0
            return self
        ok

        # Determine where actual user arguments start
        nStartIndex = 1
        for i = 1 to min(nLen, 2)
            cLower = lower(aArgs[i])
            if cLower = "ring" or cLower = "ring.exe" or substr(cLower, "main.ring") or substr(cLower, "ringtest")
                nStartIndex = i + 1
            ok
        next

        if nStartIndex > nLen
            return self
        ok

        for i = nStartIndex to nLen
            cArg = aArgs[i]
            cLower = lower(cArg)

            if cLower = "-h" or cLower = "--help" or cLower = "-help" or cLower = "help"
                bShowHelp = true
                return self
            but cLower = "-v" or cLower = "--version" or cLower = "-version" or cLower = "version"
                bShowVersion = true
                return self
            but left(cLower, 9) = "--filter="
                cFilter = substr(cArg, 10, len(cArg) - 9)
            but left(cLower, 8) = "-filter="
                cFilter = substr(cArg, 9, len(cArg) - 8)
            but cLower = "--watch" or cLower = "-watch" or cLower = "-w"
                bWatchMode = true
            but cLower = "--json" or cLower = "-json" or cLower = "-j"
                bJsonOutput = true
            but cLower = "--html" or cLower = "-html"
                bHtmlReport = true
                cHtmlReportPath = "reports/test-report.html"
            but left(cLower, 7) = "--html="
                bHtmlReport = true
                cHtmlReportPath = substr(cArg, 8, len(cArg) - 7)
            but left(cLower, 6) = "-html="
                bHtmlReport = true
                cHtmlReportPath = substr(cArg, 7, len(cArg) - 6)
            but cLower = "--junit" or cLower = "-junit" or cLower = "--xml" or cLower = "-xml"
                bJunitReport = true
                cJunitReportPath = "reports/test-report.xml"
            but left(cLower, 8) = "--junit="
                bJunitReport = true
                cJunitReportPath = substr(cArg, 9, len(cArg) - 8)
            but left(cLower, 7) = "-junit="
                bJunitReport = true
                cJunitReportPath = substr(cArg, 8, len(cArg) - 7)
            but left(cLower, 6) = "--xml="
                bJunitReport = true
                cJunitReportPath = substr(cArg, 7, len(cArg) - 6)
            but left(cLower, 5) = "-xml="
                bJunitReport = true
                cJunitReportPath = substr(cArg, 6, len(cArg) - 5)
            but left(cArg, 1) != "-"
                # Target path or file passed - resolve against caller dir
                cResolved = cArg
                if cCallerDir != NULL and cCallerDir != "" and left(cArg, 1) != "/" and substr(cArg, ":") = 0
                    cResolved = cCallerDir + "/" + cArg
                ok
                cResolved = substr(cResolved, char(92), "/")
                if substr(cArg, ".ring")
                    cTargetFile = cResolved
                else
                    cTargetDirectory = cResolved
                ok
            ok
        next

        return self

    private

    func min a, b
        if a < b return a ok
        return b