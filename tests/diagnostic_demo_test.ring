# tests/diagnostic_demo_test.ring
# اختبار توضيحي لتجربة التشخيص الذكي وعرض الفروق (Diff & Diagnostic Tips)

describe("Diagnostic & Rich Error Reporting Demo", func {

    itFailing("should show clean diff comparison on mismatch", func {
        cActualVersion   = "Ring 1.22"
        cExpectedVersion = "Ring 2.0"
        expect(cActualVersion).toBe(cExpectedVersion)
    }, "Demo diff mismatch")

    itFailing("should trigger R19 diagnostic tip on less parameters", func {
        # استدعاء دالة substr بمعاملين فقط رقميين لإطلاق خطأ R19 عمداً
        substr("Ring Programming", 5)
    }, "Demo R19 tip")

    itFailing("should trigger R24 diagnostic tip on uninitialized variable", func {
        # استخدام متغير غير معرّف لإطلاق خطأ R24 عمداً
        nVal = uninitialized_demo_var + 10
    }, "Demo R24 tip")

})

