# tests/math_test.ring

describe("Math Operations Suite", func {

    it("should calculate addition and subtraction correctly", func {
        expect(50 + 25).toBe(75)
        expect(100 - 30).toBe(70)
    })

    it("should handle multiplication and division", func {
        expect(6 * 7).toBe(42)
        expect(100 / 4).toBe(25)
    })

    it("should validate numerical boundaries", func {
        expect(99).toBeLessThan(100)
        expect(101).toBeGreaterThan(100)
    })

    it("should verify toBeBetween with math operations", func {
        expect(10 + 20).toBeBetween(25, 35)
        expect(100 / 2).toBeBetween(40, 60)
    })
})