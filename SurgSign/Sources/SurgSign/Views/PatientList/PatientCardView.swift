import SwiftUI

struct PatientCardView: View {
    let patient: Patient
    let onTap: () -> Void
    let onDelete: () -> Void

    @State private var swipeOffset: CGFloat = 0
    @State private var showDeleteButton = false

    private let deleteThreshold: CGFloat = -80

    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete action background
            if showDeleteButton || swipeOffset < 0 {
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            swipeOffset = 0
                            showDeleteButton = false
                        }
                        onDelete()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "trash.fill")
                                .font(.title3)
                            Text("Delete")
                                .font(.caption2.weight(.medium))
                        }
                        .foregroundStyle(.white)
                        .frame(width: 80)
                        .frame(maxHeight: .infinity)
                        .background(Color.surgRed, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
            }

            // Card content
            Button(action: onTap) {
                HStack(spacing: 0) {
                    PriorityBarView(priority: patient.priority)

                    VStack(alignment: .leading, spacing: 8) {
                        topRow
                        secondRow
                        diagnosisRow
                        badgesRow
                        allergiesRow
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color.surgSurface, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .offset(x: swipeOffset)
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { value in
                        let translation = value.translation.width
                        if translation < 0 {
                            swipeOffset = translation
                        } else if showDeleteButton {
                            swipeOffset = deleteThreshold + translation
                            if swipeOffset > 0 { swipeOffset = 0 }
                        }
                    }
                    .onEnded { value in
                        withAnimation(.easeOut(duration: 0.2)) {
                            if swipeOffset < deleteThreshold {
                                swipeOffset = deleteThreshold
                                showDeleteButton = true
                            } else {
                                swipeOffset = 0
                                showDeleteButton = false
                            }
                        }
                    }
            )
        }
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Patient", systemImage: "trash")
            }
        }
    }

    // MARK: - Top Row (Name + Room)

    private var topRow: some View {
        HStack(alignment: .center) {
            Text(patient.name)
                .font(.headline)
                .foregroundStyle(Color.surgText)
                .lineLimit(1)

            Spacer()

            if !patient.room.isEmpty {
                Text(patient.room)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.surgAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.surgAccent.opacity(0.12), in: Capsule())
            }
        }
    }

    // MARK: - Second Row (MRN + Surgeon)

    private var secondRow: some View {
        HStack(spacing: 12) {
            if !patient.mrn.isEmpty {
                Label(patient.mrn, systemImage: "number")
                    .font(.caption)
                    .foregroundStyle(Color.surgTextSecondary)
            }

            if !patient.surgeon.isEmpty {
                Label(patient.surgeon, systemImage: "person.fill")
                    .font(.caption)
                    .foregroundStyle(Color.surgTextSecondary)
            }
        }
    }

    // MARK: - Diagnosis

    @ViewBuilder
    private var diagnosisRow: some View {
        if !patient.diagnosis.isEmpty {
            Text(patient.diagnosis)
                .font(.subheadline)
                .foregroundStyle(Color.surgText.opacity(0.85))
                .lineLimit(2)
        }
    }

    // MARK: - Badges Row

    private var badgesRow: some View {
        HStack(spacing: 8) {
            PODBadgeView(surgeryDate: patient.surgeryDate)

            CodeStatusBadgeView(codeStatus: patient.codeStatus)

            if !patient.tasks.isEmpty {
                taskBadge
            }

            Spacer()

            Image(systemName: patient.priority.icon)
                .font(.caption)
                .foregroundStyle(patient.priority.color)
        }
    }

    private var taskBadge: some View {
        let completed = patient.completedTaskCount
        let total = patient.tasks.count
        let allDone = completed == total

        return HStack(spacing: 3) {
            Image(systemName: allDone ? "checkmark.circle.fill" : "circle.dotted")
                .font(.caption2)
            Text("\(completed)/\(total)")
                .font(.caption2.weight(.medium))
        }
        .foregroundStyle(allDone ? Color.surgGreen : Color.surgTextSecondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            (allDone ? Color.surgGreen : Color.surgTextSecondary).opacity(0.12),
            in: Capsule()
        )
    }

    // MARK: - Allergies

    @ViewBuilder
    private var allergiesRow: some View {
        let allergies = patient.allergies.trimmingCharacters(in: .whitespacesAndNewlines)
        if !allergies.isEmpty && allergies.uppercased() != "NKDA" {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
                Text(allergies)
                    .font(.caption)
                    .lineLimit(1)
            }
            .foregroundStyle(Color.surgRed)
        }
    }
}
