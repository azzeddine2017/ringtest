# tests/extended_assertions_test.ring

describe("Extended Matchers & Assertions Suite", func {

    it("verifies toBeNull and toBeNotNull", func {
        expect(NULL).toBeNull()
        expect("Ring").toBeNotNull()
        expect(100).toBeNotNull()
        expect([]).toBeNotNull()
    })

    it("verifies type checking matchers (toBeString, toBeNumber, toBeList, toBeObject)", func {
        expect("Hello Ring").toBeString()
        expect(42).toBeNumber()
        expect(3.14159).toBeNumber()
        expect([1, 2, 3]).toBeList()
        expect(new Expectation(10)).toBeObject()
    })

    it("verifies boundary comparisons (toBeGreaterThanOrEqual, toBeLessThanOrEqual)", func {
        expect(10).toBeGreaterThanOrEqual(10)
        expect(15).toBeGreaterThanOrEqual(10)
        expect(10).toBeLessThanOrEqual(10)
        expect(5).toBeLessThanOrEqual(10)
    })

    it("verifies floating point approximation (toBeCloseTo)", func {
        expect(0.1 + 0.2).toBeCloseTo(0.3, 0.0001)
        expect(3.14159).toBeCloseTo(3.14, 0.01)
    })

    it("verifies string prefix and suffix matchers (toStartWith, toEndWith)", func {
        expect("Ring Programming Language").toStartWith("Ring")
        expect("Ring Programming Language").toEndWith("Language")
    })

    it("verifies sorted list assertion (toBeSorted)", func {
        expect([1, 2, 3, 4, 5]).toBeSorted()
        expect(["alpha", "beta", "gamma"]).toBeSorted()
    })

    it("verifies exception assertions (toThrowError, notToThrow)", func {
        expect("x = 10 / 0").toThrowError("Zero")
        expect("a = 5 + 5").notToThrow()
    })

    it("verifies mock spy assertions (toHaveBeenCalled, toHaveBeenCalledTimes)", func {
        m = mock("calcTax", NULL)
        expect(m.wasCalled()).toBeFalsy()
        m.doCall()
        m.doCall()
        expect(m).toHaveBeenCalled()
        expect(m).toHaveBeenCalledTimes(2)
        restore("calcTax")
    })
})
