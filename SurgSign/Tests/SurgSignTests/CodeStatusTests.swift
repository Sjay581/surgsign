import Testing
@testable import SurgSign

@Suite("CodeStatus")
struct CodeStatusTests {

    @Test("raw values match PWA-compatible strings")
    func rawValues() {
        #expect(CodeStatus.fullCode.rawValue == "Full Code")
        #expect(CodeStatus.dnr.rawValue == "DNR")
        #expect(CodeStatus.dni.rawValue == "DNI")
        #expect(CodeStatus.dnrDni.rawValue == "DNR/DNI")
        #expect(CodeStatus.comfortMeasures.rawValue == "Comfort Measures")
    }

    @Test("shortLabel for each case")
    func shortLabels() {
        #expect(CodeStatus.fullCode.shortLabel == "Full")
        #expect(CodeStatus.dnr.shortLabel == "DNR")
        #expect(CodeStatus.dni.shortLabel == "DNI")
        #expect(CodeStatus.dnrDni.shortLabel == "DNR/DNI")
        #expect(CodeStatus.comfortMeasures.shortLabel == "CMO")
    }

    @Test("CaseIterable exposes five cases")
    func allCases() {
        #expect(CodeStatus.allCases.count == 5)
    }
}
