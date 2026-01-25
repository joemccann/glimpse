import SwiftUI

struct TaskDetailView: View {
    let task: Task
    let onAddNote: (String) -> Void
    let onDismiss: () -> Void

    @State private var noteText = ""
    @Environment(\.colorScheme) var colorScheme

    private var bgSurface: Color {
        colorScheme == .dark ? Theme.darkBgSurface : Theme.lightBgSurface
    }

    private var textPrimary: Color {
        colorScheme == .dark ? Theme.darkTextPrimary : Theme.lightTextPrimary
    }

    private var textSecondary: Color {
        colorScheme == .dark ? Theme.darkTextSecondary : Theme.lightTextSecondary
    }

    private var borderColor: Color {
        colorScheme == .dark ? Theme.darkBorder : Theme.lightBorder
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("#\(task.id)")
                        .font(.caption)
                        .foregroundColor(textSecondary)
                    Text(task.subject)
                        .font(.headline)
                        .foregroundColor(textPrimary)
                }

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(textSecondary)
                }
                .buttonStyle(.plain)
            }

            Divider()

            // Status
            HStack {
                Text("Status:")
                    .foregroundColor(textSecondary)
                StatusBadge(status: task.status)
            }

            // Description
            if let description = task.description, !description.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Description")
                        .font(.subheadline)
                        .foregroundColor(textSecondary)

                    ScrollView {
                        Text(description)
                            .font(.body)
                            .foregroundColor(textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 150)
                }
            }

            // Dependencies
            if let blocks = task.blocks, !blocks.isEmpty {
                HStack {
                    Text("Blocks:")
                        .foregroundColor(textSecondary)
                    Text(blocks.joined(separator: ", "))
                        .foregroundColor(Theme.warning)
                }
            }

            if let blockedBy = task.blockedBy, !blockedBy.isEmpty {
                HStack {
                    Text("Blocked by:")
                        .foregroundColor(textSecondary)
                    Text(blockedBy.joined(separator: ", "))
                        .foregroundColor(Theme.warning)
                }
            }

            Divider()

            // Add note
            VStack(alignment: .leading, spacing: 8) {
                Text("Add Note")
                    .font(.subheadline)
                    .foregroundColor(textSecondary)

                TextEditor(text: $noteText)
                    .frame(height: 60)
                    .padding(4)
                    .background(bgSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(borderColor, lineWidth: 1)
                    )

                Button("Add Note") {
                    if !noteText.isEmpty {
                        onAddNote(noteText)
                        noteText = ""
                    }
                }
                .disabled(noteText.isEmpty)
            }

            Spacer()
        }
        .padding()
        .frame(width: 350, height: 450)
        .background(bgSurface)
    }
}

struct StatusBadge: View {
    let status: TaskStatus

    var color: Color {
        switch status {
        case .pending: return Theme.darkTextSecondary
        case .inProgress: return Theme.accent
        case .completed: return Theme.success
        }
    }

    var label: String {
        switch status {
        case .pending: return "Pending"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        }
    }

    var body: some View {
        Text(label)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(4)
    }
}
