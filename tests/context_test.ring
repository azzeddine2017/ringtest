# tests/context_test.ring
#
# The context is a shared key/value store that outlives the eval() scope, so it
# is the supported way to share state between a suite's tests.

describe("Context Suite", func {

    it("stores and reads back a string", func {
        ctxSet("cName", "ringtest")
        expect(ctxGet("cName")).toBe("ringtest")
    })

    it("keeps values across tests", func {
        expect(ctxGet("cName")).toBe("ringtest")
    })

    it("overwrites an existing key", func {
        ctxSet("cName", "updated")
        expect(ctxGet("cName")).toBe("updated")
    })

    it("increments a counter numerically", func {
        ctxSet("nCount", 0)
        ctxIncr("nCount")
        ctxIncr("nCount")
        expect(ctxGet("nCount")).toBe(2)
    })

    it("adds an arbitrary step", func {
        ctxSet("nScore", 10)
        ctxAdd("nScore", 5)
        expect(ctxGet("nScore")).toBe(15)
    })
})
