import SwiftUI

struct DeleteConfirmationView: View {
    let session: Session
    let onConfirm: () -> Void
    let onCancel: () -> Void

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

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(Theme.warning)
                    .font(.title2)

                Text("Delete Session?")
                    .font(.headline)
                    .foregroundColor(textPrimary)

                Spacer()
            }

            Divider()

            // Session details
            VStack(alignment: .leading, spacing: 8) {
                DetailRow(label: "Session", value: session.displayName)
                DetailRow(label: "Tasks", value: "\(session.taskCount) total")

                HStack(spacing: 12) {
                    StatusCount(count: session.pending, label: "pending", color: Theme.darkTextSecondary)
                    StatusCount(count: session.inProgress, label: "active", color: Theme.accent)
                    StatusCount(count: session.completed, label: "done", color: Theme.success)
                }
                .padding(.vertical, 4)

                if let reason = session.orphanReason {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(Theme.warning)
                        Text(reason)
                            .font(.caption)
                            .foregroundColor(Theme.warning)
                    }
                }
            }

            Divider()

            // Warning
            Text("This will permanently delete all task files in this session. This action cannot be undone.")
                .font(.caption)
                .foregroundColor(textSecondary)
                .multilineTextAlignment(.center)

            // Buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.escape)

                Button("Delete Permanently") {
                    onConfirm()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .keyboardShortcut(.return)
            }
        }
        .padding(20)
        .frame(width: 320)
        .background(bgSurface)
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack {
            Text(label + ":")
                .foregroundColor(colorScheme == .dark ? Theme.darkTextSecondary : Theme.lightTextSecondary)
            Text(value)
                .foregroundColor(colorScheme == .dark ? Theme.darkTextPrimary : Theme.lightTextPrimary)
        }
        .font(.subheadline)
    }
}

private struct StatusCount: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text("\(count)")
                .fontWeight(.medium)
            Text(label)
        }
        .font(.caption)
        .foregroundColor(color)
    }
}
