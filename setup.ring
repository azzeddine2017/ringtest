# setup.ring - Pure Ring Cross-Platform Installer for ringtest
# Works on Windows, Linux, and macOS

load "stdlibcore.ring"

func main
    aArgs = sysargv
    cAction = "install"
    if len(aArgs) >= 3
        cAction = lower(trim(aArgs[3]))
    ok

    if cAction = "remove" or cAction = "uninstall" or cAction = "--uninstall" or cAction = "-u"
        uninstallRingtest()
    else
        installRingtest()
    ok

func installRingtest
    ? "================================================="
    ? "Installing ringtest CLI to active Ring environment"
    ? "================================================="

    cRingBin = normalizePath(exefolder())
    cRingRoot = normalizePath(cRingBin + "/..")
    cTargetPkg = normalizePath(cRingRoot + "/tools/ringpm/packages/ringtest")
    cSourceDir = normalizePath(currentdir())

    ? "Ring Binary Directory: " + cRingBin
    ? "Target Package Path:   " + cTargetPkg
    ? "Source Directory:      " + cSourceDir
    ? "-------------------------------------------------"

    # Ensure target package directories exist
    ensureDirectory(cTargetPkg)
    ensureDirectory(cTargetPkg + "/src")
    ensureDirectory(cTargetPkg + "/tests")

    # Copy root files
    copyFileSafely(cSourceDir + "/main.ring", cTargetPkg + "/main.ring")
    copyFileSafely(cSourceDir + "/package.ring", cTargetPkg + "/package.ring")
    copyFileSafely(cSourceDir + "/setup.ring", cTargetPkg + "/setup.ring")
    copyFileSafely(cSourceDir + "/README.md", cTargetPkg + "/README.md")
    copyFileSafely(cSourceDir + "/LICENSE", cTargetPkg + "/LICENSE")

    # Copy src recursively
    if direxists(cSourceDir + "/src")
        copyDirectoryRecursive(cSourceDir + "/src", cTargetPkg + "/src")
    ok

    # Copy tests recursively
    if direxists(cSourceDir + "/tests")
        copyDirectoryRecursive(cSourceDir + "/tests", cTargetPkg + "/tests")
    ok

    # Install global load stub in Ring's bin/load folder
    installLoadStub(cRingBin)

    # Install CLI launcher in Ring's bin directory
    installLauncher(cRingBin, cTargetPkg)

    ? "================================================="
    ? "ringtest successfully installed!"
    ? "You can now use 'ringtest' from any directory:"
    ? "  ringtest"
    ? "  ringtest --help"
    ? "  ringtest --version"
    ? "  ringtest tests/sample_test.ring"
    ? "Or include it in your Ring code:"
    ? '  load "ringtest.ring"'
    ? "================================================="

func uninstallRingtest
    ? "================================================="
    ? "Uninstalling ringtest from Ring environment"
    ? "================================================="

    cRingBin = normalizePath(exefolder())
    cRingRoot = normalizePath(cRingBin + "/..")
    cTargetPkg = normalizePath(cRingRoot + "/tools/ringpm/packages/ringtest")

    # Remove launchers
    if iswindows()
        cLauncher = cRingBin + "/ringtest.bat"
        if fexists(cLauncher)
            remove(cLauncher)
            ? "Removed: " + cLauncher
        ok
    else
        cLauncher = cRingBin + "/ringtest"
        if fexists(cLauncher)
            remove(cLauncher)
            ? "Removed: " + cLauncher
        ok
    ok

    # Remove load stub
    cLoadStub = cRingBin + "/load/ringtest.ring"
    if fexists(cLoadStub)
        remove(cLoadStub)
        ? "Removed load stub: " + cLoadStub
    ok

    # Remove package folder if exists
    if direxists(cTargetPkg)
        system(getRemoveDirCmd(cTargetPkg))
        ? "Removed package directory: " + cTargetPkg
    ok

    ? "================================================="
    ? "ringtest successfully uninstalled!"
    ? "================================================="

func installLoadStub cRingBin
    cLoadDir = cRingBin + "/load"
    ensureDirectory(cLoadDir)
    cStubPath = cLoadDir + "/ringtest.ring"
    cStubContent = 'load "/../../tools/ringpm/packages/ringtest/src/ringtest.ring"' + windowsNl()
    write(cStubPath, cStubContent)
    ? "Installed load stub: " + cStubPath

func installLauncher cRingBin, cTargetPkg
    if iswindows()
        cLauncherPath = cRingBin + "/ringtest.bat"
        cContent = '@echo off' + windowsNl() +
                   'rem ringtest CLI launcher' + windowsNl() +
                   'set "RINGTEST_CALLER_DIR=%CD%"' + windowsNl() +
                   'pushd "%~dp0..\tools\ringpm\packages\ringtest"' + windowsNl() +
                   'ring main.ring %*' + windowsNl() +
                   'set "EXIT_CODE=%ERRORLEVEL%"' + windowsNl() +
                   'popd' + windowsNl() +
                   'exit /b %EXIT_CODE%' + windowsNl()
        write(cLauncherPath, cContent)
        ? "Installed Windows launcher: " + cLauncherPath
    else
        cLauncherPath = cRingBin + "/ringtest"
        cContent = '#!/usr/bin/env bash' + char(10) +
                   '# ringtest CLI launcher' + char(10) +
                   'export RINGTEST_CALLER_DIR="$(pwd)"' + char(10) +
                   'SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"' + char(10) +
                   'cd "$SCRIPT_DIR/../tools/ringpm/packages/ringtest"' + char(10) +
                   'ring main.ring "$@"' + char(10) +
                   'EXIT_CODE=$?' + char(10) +
                   'cd "$RINGTEST_CALLER_DIR"' + char(10) +
                   'exit $EXIT_CODE' + char(10)
        write(cLauncherPath, cContent)
        system('chmod +x "' + cLauncherPath + '"')
        ? "Installed Unix launcher: " + cLauncherPath
    ok

func copyFileSafely cSrc, cDest
    if fexists(cSrc)
        cData = read(cSrc)
        write(cDest, cData)
        ? "  [+] " + getFilenameOnly(cDest)
        return true
    ok
    return false

func copyDirectoryRecursive cSrcDir, cDestDir
    ensureDirectory(cDestDir)
    aDirList = dir(cSrcDir)
    for aItem in aDirList
        cName = aItem[1]
        lIsDir = aItem[2]
        if cName = "." or cName = ".."
            loop
        ok
        cSrcSub = cSrcDir + "/" + cName
        cDestSub = cDestDir + "/" + cName
        if lIsDir
            copyDirectoryRecursive(cSrcSub, cDestSub)
        else
            cData = read(cSrcSub)
            write(cDestSub, cData)
            ? "  [+] " + cName
        ok
    next

func ensureDirectory cPath
    cNorm = normalizePath(cPath)
    if direxists(cNorm)
        return true
    ok
    aParts = split(cNorm, "/")
    cCurrent = ""
    for i = 1 to len(aParts)
        cPart = aParts[i]
        if cPart = ""
            cCurrent = "/"
            loop
        ok
        if cCurrent = ""
            cCurrent = cPart
        else
            if cCurrent = "/"
                cCurrent = "/" + cPart
            else
                cCurrent = cCurrent + "/" + cPart
            ok
        ok
        if not direxists(cCurrent)
            if not (len(cCurrent) = 2 and substr(cCurrent, 2, 1) = ":")
                system(getMakeDirCmd(cCurrent))
            ok
        ok
    next
    return direxists(cNorm)

func getMakeDirCmd cDir
    if iswindows()
        return 'mkdir "' + substr(cDir, "/", char(92)) + '" >nul 2>nul'
    else
        return 'mkdir -p "' + cDir + '" >/dev/null 2>&1'
    ok

func getRemoveDirCmd cDir
    if iswindows()
        return 'rmdir /s /q "' + substr(cDir, "/", char(92)) + '" >nul 2>nul'
    else
        return 'rm -rf "' + cDir + '" >/dev/null 2>&1'
    ok

func normalizePath cPath
    cStr = substr(cPath, char(92), "/")
    while substr(cStr, "//") > 0
        cStr = substr(cStr, "//", "/")
    end
    if len(cStr) > 1 and substr(cStr, len(cStr), 1) = "/"
        if not (len(cStr) = 3 and substr(cStr, 2, 2) = ":/")
            cStr = left(cStr, len(cStr) - 1)
        ok
    ok
    return cStr

func getFilenameOnly cPath
    cNorm = normalizePath(cPath)
    nPos = 0
    for i = len(cNorm) to 1 step -1
        if substr(cNorm, i, 1) = "/"
            nPos = i
            exit
        ok
    next
    if nPos > 0
        return substr(cNorm, nPos + 1)
    ok
    return cNorm