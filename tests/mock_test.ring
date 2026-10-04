# tests/mock_test.ring
#
# Verifies the mock registry in src/core/mock.ring.
# NOTE: mocks are a registry + call-recorder; the framework does NOT yet swap the
# real function implementation (Ring has no runtime function-rebinding hook).

describe("Mock Suite", func {

    it("registers a mock and reports it as called", func {
        oMock = mock("someTarget", NULL)
        expect(oMock.wasCalled()).toBeFalsy()
        oMock.doCall()
        expect(oMock.wasCalled()).toBeTruthy()
    })

    it("counts calls", func {
        oMock = mock("counterTarget", NULL)
        oMock.doCall()
        oMock.doCall()
        oMock.doCall()
        expect(oMock.getCallCount()).toBe(3)
    })

    it("returns the registered mock by name", func {
        mock("namedTarget", NULL)
        oFound = getMock("namedTarget")
        expect(isNull(oFound)).toBeFalsy()
        expect(oFound.cFuncName).toBe("namedTarget")
    })

    it("restores a single mock", func {
        mock("restoreTarget", NULL)
        expect(isNull(getMock("restoreTarget"))).toBeFalsy()
        restore("restoreTarget")
        expect(isNull(getMock("restoreTarget"))).toBeTruthy()
    })

    it("restores all mocks", func {
        mock("aTarget", NULL)
        mock("bTarget", NULL)
        restoreAll()
        expect(isNull(getMock("aTarget"))).toBeTruthy()
        expect(isNull(getMock("bTarget"))).toBeTruthy()
    })
})
