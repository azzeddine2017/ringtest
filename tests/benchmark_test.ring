# tests/benchmark_test.ring

describe("Benchmark Integration Suite", func {

    it("measures execution of single benchmark", func {
        res = benchmark("String Concatenation", 100, func {
            s = ""
            for i = 1 to 50
                s += "a"
            next
        })

        expect(res[:name]).toBe("String Concatenation")
        expect(res[:iterations]).toBe(100)
        expect(res[:opsPerSec]).toBeGreaterThan(0)
    })

    it("measures time with chronos / TestTimer API", func {
        t = chronos()
        t.reset()
        sum = 0
        for i = 1 to 1000
            sum += i
        next
        expect(t.elapsed_ns()).toBeGreaterThanOrEqual(0)
        expect(t.elapsed_ms()).toBeGreaterThanOrEqual(0)
        expect(len(t.elapsed())).toBeGreaterThan(0)
    })
})
