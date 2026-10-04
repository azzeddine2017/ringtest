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