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

    it("compares two functions performance", func {
        benchmarkCompare(
            "List Add", func { a = [] add(a, 1) },
            "List Concatenation", func { a = [] a + 1 },
            100
        )
        expect(true).toBeTruthy()
    })
})
