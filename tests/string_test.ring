# tests/string_test.ring

describe("String Utilities Suite", func {

    it("should concatenate strings correctly", func {
        cFirst = "Ring"
        cSecond = "Language"
        expect(cFirst + " " + cSecond).toBe("Ring Language")
    })

    it("should verify string length and content", func {
        cStr = "Developer Experience"
        expect(len(cStr)).toBe(20)
        expect(cStr).toContain("Developer")
        expect(cStr).toContain("Experience")
    })

    it("should verify truthiness for empty and non-empty strings", func {
        expect("hello").toBeTruthy()
        expect("").toBeFalsy()
    })

    it("should verify toMatch with string patterns", func {
        expect("Ring 1.21").toMatch("Ring")
        expect("test_case").toMatch("_")
    })

    it("should verify toHaveLength with strings", func {
        expect("Ring").toHaveLength(4)
        expect("").toHaveLength(0)
    })
})