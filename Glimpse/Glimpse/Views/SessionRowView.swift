import SwiftUI

struct SessionRowView: View {
    let session: Session
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false
    @Environment(\.colorScheme) var colorScheme

    private var textPrimary: Color {
        colorScheme == .dark ? Theme.darkTextPrimary : Theme.lightTextPrimary
    }

    private var textSecondary: Color {
        colorScheme == .dark ? Theme.darkTextSecondary : Theme.lightTextSecondary
    }

    private var bgHover: Color {
        colorScheme == .dark ? Theme.darkBgHover : Theme.lightBgHover
    }

    var body: some View {
        HStack(spacing: 8) {
            // Selection indicator
            Circle()
                .fill(isSelected ? Theme.accent : Color.clear)
                .frame(width: 6, height: 6)

            // Session info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(session.displayName)
                        .font(.subheadline)
                        .foregroundColor(session.isOrphan ? textSecondary : textPrimary)
                        .lineLimit(1)

                    if session.isOrphan {
                        Text("orphan")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Theme.warning.opacity(0.8))
                            .cornerRadius(3)
                    }
                }

                HStack(spacing: 4) {
                    Text("\(session.taskCount) tasks")
                        .font(.caption)
                        .foregroundColor(textSecondary)

                    if session.hasActiveTasks {
                        Circle()
                            .fill(Theme.accent)
                            .frame(width: 5, height: 5)
                    }
                }
            }

            Spacer()

            // Delete button (shows on hover)
            if isHovering {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
                .help("Delete this session")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isHovering ? bgHover : Color.clear)
        .cornerRadius(6)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture {
            onSelect()
        }
    }
}
