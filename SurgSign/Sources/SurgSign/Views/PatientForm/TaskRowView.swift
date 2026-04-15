import SwiftUI

/// A single task row displaying a checkmark toggle, task text, and a delete button.
struct TaskRowView: View {
    let task: PatientFormViewModel.TaskItem
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.isDone ? Color.surgGreen : Color.surgTextSecondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)

            Text(task.text)
                .font(.subheadline)
                .foregroundStyle(task.isDone ? Color.surgTextSecondary : Color.surgText)
                .strikethrough(task.isDone, color: Color.surgTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(2)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(Color.surgRed.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggle)
    }
}
