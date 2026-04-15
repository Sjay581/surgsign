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
        }
    }
}
