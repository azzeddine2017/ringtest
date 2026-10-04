# tests/hooks_test.ring
#
# Hooks are GLOBAL to the test file. Shared state must live in the framework
# context (ctxSet / ctxGet / ctxIncr) - a test file's own top-level variables are
# NOT visible from inside it()/beforeEach callbacks (the eval() scope pops).

ctxSet("nGlobalBeforeEach", 0)
ctxSet("nGlobalAfterEach", 0)
ctxSet("nSuiteBeforeAll", 0)
ctxSet("nSuiteBeforeEach", 0)
ctxSet("nSuiteAfterEach", 0)

beforeEach(func {
    ctxIncr("nGlobalBeforeEach")
})

afterEach(func {
    ctxIncr("nGlobalAfterEach")
})

describe("Hooks Suite - Lifecycle Hooks", func {

    beforeAll(func {
        ctxIncr("nSuiteBeforeAll")
    })

    beforeEach(func {
        ctxIncr("nSuiteBeforeEach")
    })

    afterEach(func {
        ctxIncr("nSuiteAfterEach")
    })

    test("should execute beforeAll exactly once before any test", func {
        expect(ctxGet("nSuiteBeforeAll")).toBe(1)
        expect(ctxGet("nSuiteBeforeEach")).toBe(1)
        expect(ctxGet("nGlobalBeforeEach")).toBe(1)
    })

    it("should execute beforeEach on subsequent tests", func {
        expect(ctxGet("nSuiteBeforeAll")).toBe(1)
        expect(ctxGet("nSuiteBeforeEach")).toBe(2)
        expect(ctxGet("nGlobalBeforeEach")).toBe(2)
        expect(ctxGet("nSuiteAfterEach")).toBe(1)
        expect(ctxGet("nGlobalAfterEach")).toBe(1)
    })

    test("should have accumulated afterEach calls after third test", func {
        expect(ctxGet("nSuiteBeforeAll")).toBe(1)
        expect(ctxGet("nSuiteBeforeEach")).toBe(3)
        expect(ctxGet("nSuiteAfterEach")).toBe(2)
        expect(ctxGet("nGlobalAfterEach")).toBe(2)
    })
})
