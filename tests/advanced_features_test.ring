# tests/advanced_features_test.ring

describe("Advanced Framework Features Suite", func {

    it("runs normal tests properly", func {
        expect(1 + 1).toBe(2)
    })

    itSkip("demonstrates skipped test case", "work in progress")

    itTodo("demonstrates todo test case")

    itFailing("demonstrates expected failure (xfail)", func {
        expect(10).toBe(999)
    }, "Known issue awaiting fix")

    itEach([[1, 2, 3], [10, 20, 30], [5, 5, 10]], "calculates addition %1 + %2 = %3", func a, b, cExpected {
        expect(a + b).toBe(cExpected)
    })

    itEach(["apple", "banana", "cherry"], "validates non-empty fruits: %1", func fruit {
        expect(len(fruit)).toBeGreaterThan(0)
    })
})
