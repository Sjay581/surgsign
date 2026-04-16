import SwiftUI

struct PriorityBarView: View {
    let priority: Priority

    var body: some View {
        Rectangle()
            .fill(priority.color)
            .frame(width: 4)
            .clipShape(UnevenRoundedRectangle(
                topLeadingRadius: 16,
                bottomLeadingRadius: 16,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0
            ))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Priority: \(priority.label)")
    }
}
