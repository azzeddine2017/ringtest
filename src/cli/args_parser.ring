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

    func parse aArgs
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
            # No custom arguments provided, use caller directory if available
            if cCallerDir != NULL and cCallerDir != ""
                cTargetDirectory = cCallerDir
            ok
            return self
        ok

        for i = nStartIndex to nLen
            cArg = aArgs[i]

            if cArg = "-h" or cArg = "--help" or cArg = "help"
                bShowHelp = true
                return self
            but cArg = "-v" or cArg = "--version" or cArg = "version"
                bShowVersion = true
                return self
            but left(cArg, 9) = "--filter="
                cFilter = substr(cArg, 10, len(cArg))
            but cArg = "--watch" or cArg = "-w"
                bWatchMode = true
            but cArg = "--json" or cArg = "-j"
                bJsonOutput = true
            but left(cArg, 2) != "-"
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