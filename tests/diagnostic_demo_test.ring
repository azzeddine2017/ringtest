# tests/diagnostic_demo_test.ring
# اختبار توضيحي لتجربة التشخيص الذكي وعرض الفروق (Diff & Diagnostic Tips)

describe("Diagnostic & Rich Error Reporting Demo", func {

    it("should show clean diff comparison on mismatch", func {
        cActualVersion   = "Ring 1.22"
        cExpectedVersion = "Ring 2.0"
        expect(cActualVersion).toBe(cExpectedVersion)
    })

    it("should trigger R19 diagnostic tip on less parameters", func {
        # استدعاء دالة substr بمعاملين فقط رقميين لإطلاق خطأ R19 عمداً
        substr("Ring Programming", 5)
    })

    it("should trigger R24 diagnostic tip on uninitialized variable", func {
        # استخدام متغير غير معرّف لإطلاق خطأ R24 عمداً
        nVal = uninitialized_demo_var + 10
    })

})
