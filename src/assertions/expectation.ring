# src/assertions/expectation.ring

func expect vActual
    return new Expectation(vActual)

class Expectation
    vActualValue

    func init vVal
        vActualValue = vVal
        return self

    func toBe vExpected
        if vActualValue != vExpected
            raise("AssertionError: Expected [" + string(vExpected) + "] but received [" + string(vActualValue) + "]")
        ok
        return true

    func toEqual vExpected
        if !areEqual(vActualValue, vExpected)
            raise("AssertionError: Deep equality check failed. Expected [" + string(vExpected) + "] but received [" + string(vActualValue) + "]")
        ok
        return true

    func toBeTruthy
        if isNull(vActualValue) or vActualValue = 0 or vActualValue = false or vActualValue = ""
            raise("AssertionError: Expected value to be truthy, but received [" + string(vActualValue) + "]")
        ok
        return true

    func toBeFalsy
        if !(isNull(vActualValue) or vActualValue = 0 or vActualValue = false or vActualValue = "")
            raise("AssertionError: Expected value to be falsy, but received [" + string(vActualValue) + "]")
        ok
        return true

    func toContain vItem
        if isString(vActualValue)
            if !substr(vActualValue, string(vItem))
                raise("AssertionError: Expected string to contain [" + string(vItem) + "]")
            ok
        but isList(vActualValue)
            nFound = find(vActualValue, vItem)
            if nFound = 0
                raise("AssertionError: Expected list to contain item [" + string(vItem) + "]")
            ok
        else
            raise("AssertionError: toContain() expects actual value to be a string or a list")
        ok
        return true

    func toBeGreaterThan nExpected
        if !isNumber(vActualValue) or !isNumber(nExpected)
            raise("AssertionError: Both actual and expected values must be numbers for comparison")
        ok
        if !(vActualValue > nExpected)
            raise("AssertionError: Expected [" + string(vActualValue) + "] to be greater than [" + string(nExpected) + "]")
        ok
        return true

    func toBeLessThan nExpected
        if !isNumber(vActualValue) or !isNumber(nExpected)
            raise("AssertionError: Both actual and expected values must be numbers for comparison")
        ok
        if !(vActualValue < nExpected)
            raise("AssertionError: Expected [" + string(vActualValue) + "] to be less than [" + string(nExpected) + "]")
        ok
        return true

    func toThrow
        bErrorOccurred = false
        cErrorMsg = ""

        if isString(vActualValue)
            # If actual value is a function name or executable code
            try
                eval(vActualValue)
            catch
                bErrorOccurred = true
                cErrorMsg = cCatchError
            done
        else
            raise("AssertionError: toThrow() expects a string containing Ring code to evaluate")
        ok

        if !bErrorOccurred
            raise("AssertionError: Expected code to throw an error, but it executed successfully")
        ok
        return true

    func toBeBetween nMin, nMax
        if !isNumber(vActualValue) or !isNumber(nMin) or !isNumber(nMax)
            raise("AssertionError: toBeBetween() requires numeric values")
        ok
        if vActualValue < nMin or vActualValue > nMax
            raise("AssertionError: Expected [" + string(vActualValue) + "] to be between [" + string(nMin) + "] and [" + string(nMax) + "]")
        ok
        return true

    func toMatch cPattern
        if !isString(vActualValue) or !isString(cPattern)
            raise("AssertionError: toMatch() requires string values")
        ok
        if !substr(vActualValue, cPattern)
            raise("AssertionError: Expected [" + string(vActualValue) + "] to match pattern [" + string(cPattern) + "]")
        ok
        return true

    func toBeEmpty
        if isString(vActualValue)
            if vActualValue != ""
                raise("AssertionError: Expected string to be empty, but received [" + string(vActualValue) + "]")
            ok
        but isList(vActualValue)
            if len(vActualValue) > 0
                raise("AssertionError: Expected list to be empty, but received " + string(len(vActualValue)) + " items")
            ok
        else
            raise("AssertionError: toBeEmpty() expects a string or list")
        ok
        return true

    func toHaveLength nExpected
        if isString(vActualValue)
            if len(vActualValue) != nExpected
                raise("AssertionError: Expected length [" + string(nExpected) + "] but received [" + string(len(vActualValue)) + "]")
            ok
        but isList(vActualValue)
            if len(vActualValue) != nExpected
                raise("AssertionError: Expected length [" + string(nExpected) + "] but received [" + string(len(vActualValue)) + "]")
            ok
        else
            raise("AssertionError: toHaveLength() expects a string or list")
        ok
        return true

    func toBeNull
        if !isNull(vActualValue)
            raise("AssertionError: Expected NULL, but received [" + string(vActualValue) + "] (" + type(vActualValue) + ")")
        ok
        return true

    func notToBeNull
        if isNull(vActualValue)
            raise("AssertionError: Expected non-NULL value, but received NULL")
        ok
        return true

    func toBeNotNull
        return notToBeNull()

    func toBeString
        if !isString(vActualValue)
            raise("AssertionError: Expected String, but received [" + type(vActualValue) + "]")
        ok
        return true

    func toBeNumber
        if !isNumber(vActualValue)
            raise("AssertionError: Expected Number, but received [" + type(vActualValue) + "]")
        ok
        return true

    func toBeList
        if !isList(vActualValue)
            raise("AssertionError: Expected List, but received [" + type(vActualValue) + "]")
        ok
        return true

    func toBeObject
        if !isObject(vActualValue)
            raise("AssertionError: Expected Object, but received [" + type(vActualValue) + "]")
        ok
        return true

    func toBeGreaterThanOrEqual nExpected
        if !isNumber(vActualValue) or !isNumber(nExpected)
            raise("AssertionError: Both actual and expected values must be numbers for comparison")
        ok
        if !(vActualValue >= nExpected)
            raise("AssertionError: Expected [" + string(vActualValue) + "] to be >= [" + string(nExpected) + "]")
        ok
        return true

    func toBeGte nExpected
        return toBeGreaterThanOrEqual(nExpected)

    func toBeLessThanOrEqual nExpected
        if !isNumber(vActualValue) or !isNumber(nExpected)
            raise("AssertionError: Both actual and expected values must be numbers for comparison")
        ok
        if !(vActualValue <= nExpected)
            raise("AssertionError: Expected [" + string(vActualValue) + "] to be <= [" + string(nExpected) + "]")
        ok
        return true

    func toBeLte nExpected
        return toBeLessThanOrEqual(nExpected)

    func toBeCloseTo nExpected, nDelta
        if !isNumber(vActualValue) or !isNumber(nExpected)
            raise("AssertionError: toBeCloseTo() requires numeric values")
        ok
        if isNull(nDelta) or !isNumber(nDelta)
            nDelta = 0.001
        ok
        nDiff = vActualValue - nExpected
        if nDiff < 0
            nDiff = -nDiff
        ok
        if nDiff > nDelta
            raise("AssertionError: Expected [" + string(vActualValue) + "] to be close to [" + string(nExpected) + "] within delta [" + string(nDelta) + "], diff is [" + string(nDiff) + "]")
        ok
        return true

    func toStartWith cPrefix
        if !isString(vActualValue) or !isString(cPrefix)
            raise("AssertionError: toStartWith() requires string values")
        ok
        if left(vActualValue, len(cPrefix)) != cPrefix
            raise("AssertionError: Expected [" + string(vActualValue) + "] to start with [" + string(cPrefix) + "]")
        ok
        return true

    func toStartsWith cPrefix
        return toStartWith(cPrefix)

    func toEndWith cSuffix
        if !isString(vActualValue) or !isString(cSuffix)
            raise("AssertionError: toEndWith() requires string values")
        ok
        if right(vActualValue, len(cSuffix)) != cSuffix
            raise("AssertionError: Expected [" + string(vActualValue) + "] to end with [" + string(cSuffix) + "]")
        ok
        return true

    func toEndsWith cSuffix
        return toEndWith(cSuffix)

    func toBeSorted
        if !isList(vActualValue)
            raise("AssertionError: toBeSorted() requires a list value")
        ok
        nLen = len(vActualValue)
        if nLen <= 1
            return true
        ok
        for i = 1 to nLen - 1
            bGreater = false
            if isString(vActualValue[i]) and isString(vActualValue[i+1])
                bGreater = (strcmp(vActualValue[i], vActualValue[i+1]) > 0)
            else
                bGreater = (vActualValue[i] > vActualValue[i+1])
            ok
            if bGreater
                raise("AssertionError: List is not sorted in ascending order at index " + string(i) + ": [" + string(vActualValue[i]) + "] > [" + string(vActualValue[i+1]) + "]")
            ok
        next
        return true

    func toThrowError cExpectedSubstr
        bErrorOccurred = false
        cErrorMsg = ""

        if isString(vActualValue)
            try
                eval(vActualValue)
            catch
                bErrorOccurred = true
                cErrorMsg = cCatchError
            done
        else
            raise("AssertionError: toThrowError() expects a string containing Ring code to evaluate")
        ok

        if !bErrorOccurred
            raise("AssertionError: Expected code to throw an error, but it executed successfully")
        ok

        if cExpectedSubstr != "" and cExpectedSubstr != NULL
            if !substr(cErrorMsg, cExpectedSubstr) and !substr(lower(cErrorMsg), lower(cExpectedSubstr))
                raise("AssertionError: Expected error message to contain [" + string(cExpectedSubstr) + "], but caught: [" + cErrorMsg + "]")
            ok
        ok
        return true

    func notToThrow
        if isString(vActualValue)
            try
                eval(vActualValue)
            catch
                raise("AssertionError: Expected code not to throw, but caught error: " + cCatchError)
            done
        else
            raise("AssertionError: notToThrow() expects a string containing Ring code to evaluate")
        ok
        return true

    func toNotThrow
        return notToThrow()

    func toHaveBeenCalled
        if !isObject(vActualValue)
            raise("AssertionError: toHaveBeenCalled() requires a Mock object")
        ok
        try
            if !vActualValue.wasCalled()
                raise("AssertionError: Expected mock function to have been called, but call count is 0")
            ok
        catch
            raise(cCatchError)
        done
        return true

    func toHaveBeenCalledTimes nExpectedTimes
        if !isObject(vActualValue)
            raise("AssertionError: toHaveBeenCalledTimes() requires a Mock object")
        ok
        try
            nActualCalls = vActualValue.getCallCount()
            if nActualCalls != nExpectedTimes
                raise("AssertionError: Expected mock to have been called " + string(nExpectedTimes) + " times, but was called " + string(nActualCalls) + " times")
            ok
        catch
            raise(cCatchError)
        done
        return true

    private

    func areEqual vVal1, vVal2
        if type(vVal1) != type(vVal2)
            return false
        ok

        if isList(vVal1)
            if len(vVal1) != len(vVal2)
                return false
            ok
            for i = 1 to len(vVal1)
                if !areEqual(vVal1[i], vVal2[i])
                    return false
                ok
            next
            return true
        else
            return (vVal1 = vVal2)
        ok