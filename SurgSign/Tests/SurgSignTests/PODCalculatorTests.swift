import Testing
import Foundation
@testable import SurgSign

@Suite("PODCalculator")
struct PODCalculatorTests {

    // MARK: - calculate(from:)

    @Test("nil surgeryDate returns nil")
    func nilSurgeryDateReturnsNil() {
        #expect(PODCalculator.calculate(from: nil) == nil)
        #expect(PODCalculator.label(for: nil) == nil)
    }

    @Test("today returns POD 0")
    func todayReturnsZero() {
        let today = Date()
        #expect(PODCalculator.calculate(from: today) == 0)
        #expect(PODCalculator.label(for: today) == "POD 0")
    }

    @Test("three days ago returns POD 3")
    func threeDaysAgoReturnsThree() throws {
        let threeDaysAgo = try #require(
            Calendar.current.date(byAdding: .day, value: -3, to: Date())
        )
        #expect(PODCalculator.calculate(from: threeDaysAgo) == 3)
        #expect(PODCalculator.label(for: threeDaysAgo) == "POD 3")
    }

    @Test("future surgery date is pre-op")
    func futureDateIsPreOp() throws {
        let tomorrow = try #require(
            Calendar.current.date(byAdding: .day, value: 1, to: Date())
        )
        #expect(PODCalculator.calculate(from: tomorrow) == -1)
        #expect(PODCalculator.label(for: tomorrow) == "Pre-Op")
    }

    // MARK: - style(for:)

    @Test("nil pod maps to preOp")
    func styleNil() {
        #expect(PODCalculator.style(for: nil) == .preOp)
    }

    @Test("negative pod maps to preOp")
    func styleNegative() {
        #expect(PODCalculator.style(for: -3) == .preOp)
    }

    @Test("zero pod maps to dayOfSurgery")
    func styleZero() {
        #expect(PODCalculator.style(for: 0) == .dayOfSurgery)
    }

    @Test("POD 1 maps to early")
    func styleOne() {
        #expect(PODCalculator.style(for: 1) == .early)
    }

    @Test("POD 5 maps to mid")
    func styleFive() {
        #expect(PODCalculator.style(for: 5) == .mid)
    }

    @Test("POD 10 maps to late")
    func styleTen() {
        #expect(PODCalculator.style(for: 10) == .late)
    }
}
