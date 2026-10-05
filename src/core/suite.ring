# src/core/suite.ring

# Global registry holding all registered suites
aGlobalTestSuites = []

# Global lifecycle hooks
aGlobalBeforeAll  = []
aGlobalBeforeEach = []
aGlobalAfterEach  = []
aGlobalAfterAll   = []

# Active suite tracking for lexical describe() scope
nCurrentSuiteIndex = 0

# Shared context that survives across eval-scope boundaries.
aGlobalContext = []

# Global ANSI Escape Constants for Terminal Styling
C_ESC        = char(27)
C_RESET      = char(27) + "[0m"
C_BOLD       = char(27) + "[1m"
C_DIM        = char(27) + "[2m"
C_ITALIC     = char(27) + "[3m"
C_UNDERLINE  = char(27) + "[4m"

C_BLACK      = char(27) + "[30m"
C_RED        = char(27) + "[31m"
C_GREEN      = char(27) + "[32m"
C_YELLOW     = char(27) + "[33m"
C_BLUE       = char(27) + "[34m"
C_MAGENTA    = char(27) + "[35m"
C_CYAN       = char(27) + "[36m"
C_WHITE      = char(27) + "[37m"

C_BBLACK     = char(27) + "[90m"
C_BRED       = char(27) + "[91m"
C_BGREEN     = char(27) + "[92m"
C_BYELLOW    = char(27) + "[93m"
C_BBLUE      = char(27) + "[94m"
C_BMAGENTA   = char(27) + "[95m"
C_BCYAN      = char(27) + "[96m"
C_BWHITE     = char(27) + "[97m"

lGlobalColorEnabled = true

func context
    return aGlobalContext

func ctxSet cKey, vValue
    aGlobalContext[cKey] = vValue
    return vValue

func ctxGet cKey
    return aGlobalContext[cKey]

func ctxIncr cKey
    return ctxAdd(cKey, 1)

func ctxAdd cKey, nBy
    if !isNumber(nBy)
        nBy = 1
    ok
    nCur = aGlobalContext[cKey]
    if !isNumber(nCur)
        nCur = 0
    ok
    aGlobalContext[cKey] = nCur + nBy
    return aGlobalContext[cKey]

func clearGlobalSuites
    aGlobalTestSuites = []
    aGlobalBeforeAll  = []
    aGlobalBeforeEach = []
    aGlobalAfterEach  = []
    aGlobalAfterAll   = []
    aGlobalContext    = []
    nCurrentSuiteIndex = 0

func getGlobalSuites
    return aGlobalTestSuites

func getGlobalBeforeAll
    return aGlobalBeforeAll

func getGlobalBeforeEach
    return aGlobalBeforeEach

func getGlobalAfterEach
    return aGlobalAfterEach

func getGlobalAfterAll
    return aGlobalAfterAll

func describe cSuiteName, vSuiteBody
    oSuite = new TestSuite(cSuiteName)
    add(aGlobalTestSuites, oSuite)
    nOldSuiteIndex = nCurrentSuiteIndex
    nCurrentSuiteIndex = len(aGlobalTestSuites)

    if !isNull(vSuiteBody)
        vFn = vSuiteBody
        try
            call vFn()
        catch
            ? "[SUITE DEF ERROR in '" + cSuiteName + "'] " + cCatchError
            nCurrentSuiteIndex = nOldSuiteIndex
            raise(cCatchError)
        done
    ok
    nCurrentSuiteIndex = nOldSuiteIndex

func it cTestName, vTestFunc
    if len(aGlobalTestSuites) = 0
        describe("Default Suite", NULL)
    ok

    oTest = new TestCase(cTestName, vTestFunc)
    nLastIndex = len(aGlobalTestSuites)
    aGlobalTestSuites[nLastIndex].addTest(oTest)
    return oTest

func test cTestName, vTestFunc
    return it(cTestName, vTestFunc)

func itSkip cTestName, vReasonOrFunc
    oTest = it(cTestName, NULL)
    oTest.bSkipped = true
    if isString(vReasonOrFunc)
        oTest.cSkipReason = vReasonOrFunc
    ok
    return oTest

func testSkip cTestName, vReasonOrFunc
    return itSkip(cTestName, vReasonOrFunc)

func itTodo cTestName
    oTest = it(cTestName, NULL)
    oTest.bTodo = true
    oTest.bSkipped = true
    oTest.cSkipReason = "todo"
    return oTest

func testTodo cTestName
    return itTodo(cTestName)

func itFailing cTestName, vTestFunc, cReason
    oTest = it(cTestName, vTestFunc)
    oTest.bXFail = true
    oTest.cXFailReason = cReason
    return oTest

func testFailing cTestName, vTestFunc, cReason
    return itFailing(cTestName, vTestFunc, cReason)

func itXFail cTestName, vTestFunc, cReason
    return itFailing(cTestName, vTestFunc, cReason)

func testXFail cTestName, vTestFunc, cReason
    return itFailing(cTestName, vTestFunc, cReason)

func itEach aDataList, cFormatName, vTestFunc
    if !isList(aDataList) return ok
    for item in aDataList
        aParams = []
        if isList(item)
            aParams = item
        else
            aParams = [item]
        ok

        cFormatted = cFormatName
        for pIdx = 1 to len(aParams)
            cFormatted = substr(cFormatted, "%" + string(pIdx), string(aParams[pIdx]))
            cFormatted = substr(cFormatted, "{" + string(pIdx - 1) + "}", string(aParams[pIdx]))
        next

        oTest = it(cFormatted, vTestFunc)
        oTest.aParams = aParams
    next

func testEach aDataList, cFormatName, vTestFunc
    itEach(aDataList, cFormatName, vTestFunc)

func beforeAll vFn
    if nCurrentSuiteIndex > 0 and nCurrentSuiteIndex <= len(aGlobalTestSuites)
        add(aGlobalTestSuites[nCurrentSuiteIndex].aBeforeAll, vFn)
    else
        add(aGlobalBeforeAll, vFn)
    ok

func beforeEach vFn
    if nCurrentSuiteIndex > 0 and nCurrentSuiteIndex <= len(aGlobalTestSuites)
        add(aGlobalTestSuites[nCurrentSuiteIndex].aBeforeEach, vFn)
    else
        add(aGlobalBeforeEach, vFn)
    ok

func afterEach vFn
    if nCurrentSuiteIndex > 0 and nCurrentSuiteIndex <= len(aGlobalTestSuites)
        add(aGlobalTestSuites[nCurrentSuiteIndex].aAfterEach, vFn)
    else
        add(aGlobalAfterEach, vFn)
    ok

func afterAll vFn
    if nCurrentSuiteIndex > 0 and nCurrentSuiteIndex <= len(aGlobalTestSuites)
        add(aGlobalTestSuites[nCurrentSuiteIndex].aAfterAll, vFn)
    else
        add(aGlobalAfterAll, vFn)
    ok

# Classes definition
class TestCase
    cName = ""
    vCallback = NULL
    bPassed = false
    bSkipped = false
    cSkipReason = ""
    bTodo = false
    bXFail = false
    cXFailReason = ""
    cErrorMessage = ""
    nDuration = 0.0
    aParams = []

    func init cTestName, vFunc
        cName = cTestName
        vCallback = vFunc
        bPassed = false
        bSkipped = false
        cSkipReason = ""
        bTodo = false
        bXFail = false
        cXFailReason = ""
        cErrorMessage = ""
        nDuration = 0.0
        aParams = []
        return self

class TestSuite
    cName = ""
    aTests = []
    aBeforeAll = []
    aBeforeEach = []
    aAfterEach = []
    aAfterAll = []
    nPassCount = 0
    nFailCount = 0
    nSkipCount = 0
    nTotalDuration = 0.0
    lSkipAll = false
    cSkipReason = ""

    func init cSuiteName
        cName = cSuiteName
        aTests = []
        aBeforeAll = []
        aBeforeEach = []
        aAfterEach = []
        aAfterAll = []
        nPassCount = 0
        nFailCount = 0
        nSkipCount = 0
        nTotalDuration = 0.0
        lSkipAll = false
        cSkipReason = ""
        return self

    func addTest oTest
        add(aTests, oTest)

    func skipAll cReason
        lSkipAll = true
        cSkipReason = cReason