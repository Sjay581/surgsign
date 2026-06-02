import SwiftUI

struct ShiftToggleView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(spacing: 0) {
            segmentButton(label: "AM", isActive: appState.isAMShift, color: .surgAM)
            segmentButton(label: "PM", isActive: !appState.isAMShift, color: .surgPM)
        }
        .background(Color.surgSurface, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.surgBorder, lineWidth: 1))
    }

    private func segmentButton(label: String, isActive: Bool, color: Color) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                appState.toggleShift()
            }
        } label: {
            Text(label)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(isActive ? .black : Color.surgTextSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background {
                    if isActive {
                        Capsule()
                            .fill(color)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}