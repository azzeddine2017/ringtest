# src/core/mock.ring

# Simple mocking support for Ring

aMocks = []

func mock cOriginalFunc, vMockFn
    # Store original function reference and mock
    oMock = new Mock(cOriginalFunc, vMockFn)
    add(aMocks, oMock)
    return oMock

func restore cOriginalFunc
    # Find and remove mock for this function
    for i = 1 to len(aMocks)
        if aMocks[i].cFuncName = cOriginalFunc
            del(aMocks, i)
            return true
        ok
    next
    return false

func restoreAll
    aMocks = []

func getMock cOriginalFunc
    for oMock in aMocks
        if oMock.cFuncName = cOriginalFunc
            return oMock
        ok
    next
    return NULL

class Mock
    cFuncName = ""
    vMockFn = NULL
    nCallCount = 0
    aCallArgs = []

    func init cName, vFn
        cFuncName = cName
        vMockFn = vFn
        nCallCount = 0
        aCallArgs = []
        return self

    func doCall
        nCallCount++
        add(aCallArgs, sysargv)
        if !isNull(vMockFn)
            return call vMockFn()
        ok
        return NULL

    func getCallCount
        return nCallCount

    func getCallArgs nIndex
        if nIndex >= 1 and nIndex <= len(aCallArgs)
            return aCallArgs[nIndex]
        ok
        return NULL

    func wasCalled
        return nCallCount > 0
