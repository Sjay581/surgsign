import SwiftUI

struct PODBadgeView: View {
    let surgeryDate: Date?

    var body: some View {
        if let label = PODCalculator.label(for: surgeryDate) {
            let badgeColor = PODCalculator.color(for: surgeryDate)

            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(badgeColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(badgeColor.opacity(0.12), in: Capsule())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilityLabel(for: label))
        }
    }

    private func accessibilityLabel(for podLabel: String) -> String {
        if podLabel == "Pre-Op" { return "Pre-operative" }
        let digits = podLabel.filter { $0.isNumber }
        return digits.isEmpty ? podLabel : "Post-operative day \(digits)"
    }
}
