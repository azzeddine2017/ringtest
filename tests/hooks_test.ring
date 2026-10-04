# tests/hooks_test.ring
#
# Hooks are GLOBAL to the test file. Shared state must live in the framework
# context (ctxSet / ctxGet / ctxIncr) - a test file's own top-level variables are
# NOT visible from inside it()/beforeEach callbacks (the eval() scope pops).

ctxSet("nBefore", 0)
ctxSet("nAfter", 0)

beforeEach(func {
    ctxIncr("nBefore")
})

afterEach(func {
    ctxIncr("nAfter")
})

describe("Hooks Suite", func {

    it("runs beforeEach once before the first test", func {
        expect(ctxGet("nBefore")).toBe(1)
    })

    it("runs beforeEach again before the second test", func {
        expect(ctxGet("nBefore")).toBe(2)
    })

    it("ran afterEach for the two previous tests", func {
        expect(ctxGet("nAfter")).toBe(2)
    })
})
