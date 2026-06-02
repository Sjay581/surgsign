import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "stethoscope")
                .font(.system(size: 56))
                .foregroundStyle(Color.surgTextSecondary.opacity(0.5))

            Text("No Patients")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.surgTextSecondary)

            Text("Add a patient or scan a handoff QR code to get started.")
                .font(.subheadline)
                .foregroundStyle(Color.surgTextSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
        }
    }
}