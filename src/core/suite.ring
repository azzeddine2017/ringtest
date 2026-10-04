# src/core/suite.ring

# Global registry holding all registered suites
aGlobalTestSuites = []

# Global beforeEach/afterEach hooks
aGlobalBeforeEach = []
aGlobalAfterEach = []

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
    # Numeric increment by 1. Exists because ctxGet() on a missing key returns ""
    # and Ring's + then CONCATENATES: "" + 1 = "1", "1" + 1 = "11".
    # Note: Ring has no optional parameters - ctxAdd() is the 2-arg variant.
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
    aGlobalBeforeEach = []
    aGlobalAfterEach = []
    aGlobalContext = []

func getGlobalSuites
    return aGlobalTestSuites

func getGlobalBeforeEach
    return aGlobalBeforeEach

func getGlobalAfterEach
    return aGlobalAfterEach

func describe cSuiteName, vSuiteBody
    oSuite = new TestSuite(cSuiteName)
    add(aGlobalTestSuites, oSuite)

    if !isNull(vSuiteBody)
        vFn = vSuiteBody
        try
            call vFn()
        catch
            ? "[SUITE DEF ERROR in '" + cSuiteName + "'] " + cCatchError
            raise(cCatchError)
        done
    ok

func it cTestName, vTestFunc
    if len(aGlobalTestSuites) = 0
        describe("Default Suite", NULL)
    ok

    oTest = new TestCase(cTestName, vTestFunc)
    nLastIndex = len(aGlobalTestSuites)
    oSuite = ref(aGlobalTestSuites[nLastIndex])
    oSuite.addTest(oTest)

func beforeEach vFn
    add(aGlobalBeforeEach, vFn)

func afterEach vFn
    add(aGlobalAfterEach, vFn)

# Classes definition
class TestCase
    cName = ""
    vCallback = NULL
    bPassed = false
    cErrorMessage = ""
    nDuration = 0.0

    func init cTestName, vFunc
        cName = cTestName
        vCallback = vFunc
        return self

class TestSuite
    cName = ""
    aTests = []
    nPassCount = 0
    nFailCount = 0
    nTotalDuration = 0.0

    func init cSuiteName
        cName = cSuiteName
        aTests = []
        return self

    func addTest oTest
        add(aTests, oTest)