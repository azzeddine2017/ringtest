# tests/error_test.ring

describe("Exception Handling Suite", func {

    it("should detect division by zero exception", func {
        expect("1 / 0").toThrow()
    })

    it("should detect custom raised errors", func {
        expect("raise('Custom application error')").toThrow()
    })

    it("should detect syntax errors in eval", func {
        expect("invalid syntax here").toThrow()
    })
})