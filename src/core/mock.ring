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
    vReturnValue = NULL
    bHasCustomReturn = false
    nCallCount = 0
    aCallArgs = []

    func init cName, vFn
        cFuncName = cName
        vMockFn = vFn
        vReturnValue = NULL
        bHasCustomReturn = false
        nCallCount = 0
        aCallArgs = []
        return self

    func setReturn vVal
        vReturnValue = vVal
        bHasCustomReturn = true
        return self

    func mockReturnValue vVal
        return setReturn(vVal)

    func doCall
        nCallCount++
        add(aCallArgs, sysargv)
        if bHasCustomReturn
            return vReturnValue
        ok
        if !isNull(vMockFn)
            return call vMockFn()
        ok
        return NULL

    func invoke
        return doCall()

    func getCallCount
        return nCallCount

    func getCallArgs nIndex
        if nIndex >= 1 and nIndex <= len(aCallArgs)
            return aCallArgs[nIndex]
        ok
        return NULL

    func wasCalled
        return nCallCount > 0

    func wasCalledTimes nTimes
        return nCallCount = nTimes

    func reset
        nCallCount = 0
        aCallArgs = []
        vReturnValue = NULL
        bHasCustomReturn = false
