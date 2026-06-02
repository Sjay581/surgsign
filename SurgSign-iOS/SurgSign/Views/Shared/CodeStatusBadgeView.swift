import SwiftUI

struct CodeStatusBadgeView: View {
    let codeStatus: CodeStatus

    var body: some View {
        if codeStatus != .fullCode {
            Text(codeStatus.shortLabel)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(codeStatus.color, in: Capsule())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Code status: \(codeStatus.rawValue)")
        }
    }
}