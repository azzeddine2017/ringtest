# src/core/benchmark.ring

# Global Benchmark Instance
$oGlobalBenchmark = NULL

func benchmark cName, nIterations, vFunc
    if $oGlobalBenchmark = NULL
        $oGlobalBenchmark = new BenchmarkRunner
    ok
    return $oGlobalBenchmark.measure(cName, vFunc, nIterations)

func benchmarkCompare cName1, vFunc1, cName2, vFunc2, nIterations
    if $oGlobalBenchmark = NULL
        $oGlobalBenchmark = new BenchmarkRunner
    ok
    return $oGlobalBenchmark.compare(cName1, vFunc1, cName2, vFunc2, nIterations)

func chronos
    return new TestTimer()

func testTimer
    return new TestTimer()

# ======================================================================
# TestTimer: High-Precision Timekeeper (Auto-uses QalamChronos if loaded)
# ======================================================================
class TestTimer
    pChronos = NULL
    nStart = 0
    bHasQalam = false

    func init
        try
            pChronos = new QalamChronos()
            bHasQalam = true
        catch
            bHasQalam = false
            nStart = clock()
        done
        return self

    func reset
        if bHasQalam
            pChronos.reset()
        else
            nStart = clock()
        ok

    func elapsed_ns
        if bHasQalam
            return pChronos.elapsed_ns()
        ok
        return ((clock() - nStart) / clockspersecond()) * 1000000000

    func elapsed_ms
        if bHasQalam
            return pChronos.elapsed_ns() / 1000000.0
        ok
        return ((clock() - nStart) / clockspersecond()) * 1000.0

    func elapsed_s
        if bHasQalam
            return pChronos.elapsed_ns() / 1000000000.0
        ok
        return (clock() - nStart) / clockspersecond()

    func elapsed
        if bHasQalam
            return pChronos.elapsed()
        ok
        return formatTime(elapsed_s())

    private

    func formatTime nSec
        if nSec < 0.000001
            return string(floor(nSec * 1000000000)) + " ns"
        but nSec < 0.001
            return string(floor(nSec * 1000000)) + " µs"
        but nSec < 1.0
            return string(floor(nSec * 10000) / 10) + " ms"
        else
            return string(floor(nSec * 100) / 100) + " s"
        ok

# ======================================================================
# BenchmarkRunner: Automated Iteration Benchmark & Comparison Engine
# ======================================================================
class BenchmarkRunner
    aResults = []

    func measure cName, vFunc, nIterations
        if !isNumber(nIterations) or nIterations < 1
            nIterations = 1000
        ok

        oTimer = new TestTimer

        # Warm-up run (up to 10 iterations)
        nWarmup = min(nIterations, 10)
        for w = 1 to nWarmup
            safeCall(vFunc)
        next

        oTimer.reset()
        for i = 1 to nIterations
            safeCall(vFunc)
        next
        nTotal = oTimer.elapsed_s()

        if nTotal <= 0
            nTotal = 0.000001
        ok
        nAvg = nTotal / nIterations
        nOps = floor(nIterations / nTotal)

        aResult = [
            :name = cName,
            :iterations = nIterations,
            :totalTime = nTotal,
            :avgTime = nAvg,
            :opsPerSec = nOps,
            :hasQalam = oTimer.bHasQalam
        ]
        add(aResults, aResult)

        # Print formatted ANSI output
        cCyan   = char(27) + "[36m"
        cGreen  = char(27) + "[32m"
        cYellow = char(27) + "[33m"
        cGray   = char(27) + "[90m"
        cBold   = char(27) + "[1m"
        cReset  = char(27) + "[0m"

        cEngine = ""
        if oTimer.bHasQalam
            cEngine = cGreen + " (⚡ AlQalam Chronos)" + cReset
        ok

        ? cCyan + cBold + "  ⚡ BENCHMARK: " + cReset + cBold + cName + cReset +
          cGray + " (" + string(nIterations) + " iterations)" + cReset + cEngine
        ? "     " + cGray + "Total: " + cReset + formatTime(nTotal) +
          "  " + cGray + "Avg: " + cReset + formatTime(nAvg) +
          "  " + cGreen + cBold + string(nOps) + " ops/sec" + cReset
        ? ""

        return aResult

    func compare cName1, vFunc1, cName2, vFunc2, nIterations
        cCyan   = char(27) + "[36m"
        cGreen  = char(27) + "[32m"
        cBold   = char(27) + "[1m"
        cReset  = char(27) + "[0m"

        ? cCyan + cBold + "  ==================================================" + cReset
        ? cCyan + cBold + "  ⚡ BENCHMARK COMPARISON" + cReset
        ? cCyan + cBold + "  ==================================================" + cReset
        ? ""

        r1 = measure(cName1, vFunc1, nIterations)
        r2 = measure(cName2, vFunc2, nIterations)

        if r1[:avgTime] < r2[:avgTime]
            nFactor = r2[:avgTime] / r1[:avgTime]
            ? cGreen + cBold + "  🏆 " + cName1 + " is " + string(floor(nFactor * 100) / 100) + "x faster than " + cName2 + cReset
        else
            nFactor = r1[:avgTime] / r2[:avgTime]
            ? cGreen + cBold + "  🏆 " + cName2 + " is " + string(floor(nFactor * 100) / 100) + "x faster than " + cName1 + cReset
        ok
        ? ""

    private

    func safeCall vFunc
        if isNull(vFunc) return ok
        if isString(vFunc)
            call vFunc()
        else
            call vFunc()
        ok

    func formatTime nSec
        if nSec < 0.000001
            return string(floor(nSec * 1000000000)) + " ns"
        but nSec < 0.001
            return string(floor(nSec * 1000000)) + " µs"
        but nSec < 1.0
            return string(floor(nSec * 10000) / 10) + " ms"
        else
            return string(floor(nSec * 100) / 100) + " s"
        ok

    func min a, b
        if a < b return a ok
        return b
