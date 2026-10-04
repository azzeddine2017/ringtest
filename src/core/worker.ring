# src/core/worker.ring
# Isolated Worker Process for running a single test file in its own Ring VM

load "stdlibcore.ring"
load "src/ringtest.ring"

func main
    if len(sysargv) < 3
        ? "Usage: ring worker.ring <test_file_path> [project_dir] [filter]"
        shutdown(1)
    ok

    cTestFile = sysargv[3]
    cProjectDir = ""
    cFilter = ""
    if len(sysargv) >= 4
        cProjectDir = sysargv[4]
    ok
    if len(sysargv) >= 5
        cFilter = sysargv[5]
    ok

    runner = new TestRunner()
    runner.setFilter(cFilter)
    bSuccess = runner.runFileDirect(cTestFile, cProjectDir)

    if !bSuccess
        shutdown(1)
    ok
