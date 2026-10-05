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

class BenchmarkRunner
    aResults = []

    func measure cName, vFunc, nIterations
        if !isNumber(nIterations) or nIterations < 1
            nIterations = 1000
        ok

        # Warm-up run (up to 10 iterations)
        nWarmup = min(nIterations, 10)
        for w = 1 to nWarmup
            safeCall(vFunc)
        next

        nStart = clock()
        for i = 1 to nIterations
            safeCall(vFunc)
        next
        nEnd = clock()

        nTotal = (nEnd - nStart) / clockspersecond()
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
            :opsPerSec = nOps
        ]
        add(aResults, aResult)

        # Print formatted ANSI output
        cCyan   = char(27) + "[36m"
        cGreen  = char(27) + "[32m"
        cYellow = char(27) + "[33m"
        cGray   = char(27) + "[90m"
        cBold   = char(27) + "[1m"
        cReset  = char(27) + "[0m"

        ? cCyan + cBold + "  ⚡ BENCHMARK: " + cReset + cBold + cName + cReset +
          cGray + " (" + string(nIterations) + " iterations)" + cReset
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
