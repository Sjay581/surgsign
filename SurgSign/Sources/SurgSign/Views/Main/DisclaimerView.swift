import SwiftUI

struct DisclaimerView: View {
    @Environment(AppState.self) private var appState

    @State private var iconScale: CGFloat = 0.6
    @State private var contentOpacity: Double = 0.0

    var body: some View {
        ZStack {
            Color.surgBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 72))
                        .foregroundStyle(Color.surgAccent)
                        .scaleEffect(iconScale)

                    VStack(spacing: 8) {
                        Text("SurgSign")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.surgText)

                        Text("Surgical Shift Handoff Tool")
                            .font(.title3)
                            .foregroundStyle(Color.surgTextSecondary)
                    }
                }
                .padding(.bottom, 40)

                VStack(spacing: 20) {
                    disclaimerCard(
                        icon: "exclamationmark.triangle.fill",
                        title: "Prototype Application",
                        body: "This application is a prototype tool designed for surgical resident shift handoffs. It is not intended for use in production clinical environments without proper institutional review and security infrastructure."
                    )

                    disclaimerCard(
                        icon: "lock.shield.fill",
                        title: "No Real PHI",
                        body: "Do not enter real Protected Health Information (PHI) unless your institution has approved this tool with appropriate HIPAA-compliant safeguards in place."
                    )

                    disclaimerCard(
                        icon: "iphone.gen3",
                        title: "Local Storage Only",
                        body: "All patient data is stored locally on this device. Data is not transmitted to any server and will be lost if the app is deleted."
                    )
                }
                .padding(.horizontal, 24)
                .opacity(contentOpacity)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        appState.hasAcceptedDisclaimer = true
                    }
                } label: {
                    Text("I Understand")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.surgAccent, in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .opacity(contentOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.1)) {
                iconScale = 1.0
            }
            withAnimation(.easeIn(duration: 0.5).delay(0.3)) {
                contentOpacity = 1.0
            }
        }
    }

    // MARK: - Disclaimer Card

    private func disclaimerCard(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.surgAM)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.surgText)

                Text(body)
                    .font(.caption)
                    .foregroundStyle(Color.surgTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surgSurface, in: RoundedRectangle(cornerRadius: 12))
    }
}
