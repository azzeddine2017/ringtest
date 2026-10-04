# tests/sample_test.ring

describe("Basic Assertions Suite", func {

    it("should verify strict equality and comparisons", func {
        expect(10 + 5).toBe(15)
        expect("hello" + " world").toBe("hello world")
        expect(100).toBeGreaterThan(50)
        expect(25).toBeLessThan(50)
    })

    it("should check boolean truthiness and falsiness", func {
        expect(true).toBeTruthy()
        expect("non-empty string").toBeTruthy()
        expect(false).toBeFalsy()
        expect("").toBeFalsy()
        expect(0).toBeFalsy()
    })

    it("should verify lists and deep equality", func {
        aFruits = ["apple", "banana", "orange"]
        expect(aFruits).toContain("banana")
        expect([1, 2, [3, 4]]).toEqual([1, 2, [3, 4]])
    })

    it("should verify string substring matching", func {
        cText = "Ring programming language"
        expect(cText).toContain("programming")
    })

    it("should verify toBeBetween assertion", func {
        expect(50).toBeBetween(1, 100)
        expect(0).toBeBetween(-10, 10)
    })

    it("should verify toMatch assertion", func {
        expect("hello123").toMatch("hello")
        expect("test@email.com").toMatch("@")
    })

    it("should verify toBeEmpty assertion", func {
        expect("").toBeEmpty()
        expect([]).toBeEmpty()
    })

    it("should verify toHaveLength assertion", func {
        expect("hello").toHaveLength(5)
        expect([1, 2, 3]).toHaveLength(3)
    })
})