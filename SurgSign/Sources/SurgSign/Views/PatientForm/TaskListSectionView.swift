import SwiftUI

/// Reusable section for managing the task list within the patient form.
///
/// Displays existing tasks with toggle and delete controls, plus an inline
/// text field for adding new tasks.
struct TaskListSectionView: View {
    @Bindable var viewModel: PatientFormViewModel
    @FocusState private var isNewTaskFocused: Bool

    var body: some View {
        Section {
            if viewModel.tasks.isEmpty {
                emptyState
            } else {
                taskList
            }

            addTaskRow
        } header: {
            sectionHeader
        }
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        HStack {
            Text("Active Issues / Tasks")
            Spacer()
            if !viewModel.tasks.isEmpty {
                let completed = viewModel.tasks.filter(\.isDone).count
                Text("\(completed)/\(viewModel.tasks.count)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(
                        completed == viewModel.tasks.count
                            ? Color.surgGreen
                            : Color.surgTextSecondary
                    )
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: 6) {
                Image(systemName: "checklist")
                    .font(.title3)
                    .foregroundStyle(Color.surgTextSecondary.opacity(0.6))
                Text("No tasks yet")
                    .font(.caption)
                    .foregroundStyle(Color.surgTextSecondary.opacity(0.6))
            }
            .padding(.vertical, 12)
            Spacer()
        }
        .listRowBackground(Color.surgSurface)
    }

    // MARK: - Task List

    private var taskList: some View {
        ForEach(viewModel.tasks) { task in
            TaskRowView(
                task: task,
                onToggle: { viewModel.toggleTask(task) },
                onDelete: { viewModel.removeTask(task) }
            )
            .listRowBackground(Color.surgSurface)
        }
    }

    // MARK: - Add Task Row

    private var addTaskRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus.circle")
                .font(.title3)
                .foregroundStyle(Color.surgAccent.opacity(0.7))

            TextField("Add a task...", text: $viewModel.newTaskText)
                .font(.subheadline)
                .foregroundStyle(Color.surgText)
                .focused($isNewTaskFocused)
                .onSubmit {
                    addTaskIfValid()
                }

            if !viewModel.newTaskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button {
                    addTaskIfValid()
                } label: {
                    Text("Add")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.surgAccent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(Color.surgSurface)
    }

    // MARK: - Helpers

    private func addTaskIfValid() {
        viewModel.addTask()
        isNewTaskFocused = true
    }
}
