import Testing
@testable import SurgSign

@Suite("Priority")
struct PriorityTests {

    @Test("sortOrder values")
    func sortOrderValues() {
        #expect(Priority.high.sortOrder == 0)
        #expect(Priority.medium.sortOrder == 1)
        #expect(Priority.low.sortOrder == 2)
        #expect(Priority.stable.sortOrder == 3)
    }

    @Test("Comparable orders high < medium < low < stable")
    func comparableOrdering() {
        #expect(Priority.high < Priority.medium)
        #expect(Priority.medium < Priority.low)
        #expect(Priority.low < Priority.stable)

        let sorted = [Priority.stable, .low, .high, .medium].sorted()
        #expect(sorted == [.high, .medium, .low, .stable])
    }

    @Test("CaseIterable exposes exactly four cases")
    func allCasesCount() {
        #expect(Priority.allCases.count == 4)
        #expect(Set(Priority.allCases) == Set([.high, .medium, .low, .stable]))
    }
}
