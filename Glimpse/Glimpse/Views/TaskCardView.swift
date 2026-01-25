import SwiftUI

struct TaskCardView: View {
    let task: Task
    let onTap: () -> Void

    @Environment(\.colorScheme) var colorScheme

    private var bgColor: Color {
        colorScheme == .dark ? Theme.darkBgElevated : Theme.lightBgElevated
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
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("#\(task.id)")
                        .font(.caption)
                        .foregroundColor(textSecondary)

                    Spacer()

                    if task.isBlocked {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Theme.warning)
                            .font(.caption)
                    }
                }

                Text(task.subject)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let activeForm = task.activeForm, task.status == .inProgress {
                    Text(activeForm)
                        .font(.caption)
                        .foregroundColor(Theme.accent)
                        .lineLimit(1)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(bgColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .modifier(PulseModifier(isActive: task.status == .inProgress))
    }
}

struct PulseModifier: ViewModifier {
    let isActive: Bool
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .opacity(isActive && isPulsing ? 0.8 : 1.0)
            .scaleEffect(isActive && isPulsing ? 0.98 : 1.0)
            .animation(
                isActive ? Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true) : .default,
                value: isPulsing
            )
            .onAppear {
                if isActive { isPulsing = true }
            }
            .onChange(of: isActive) { newValue in
                isPulsing = newValue
            }
    }
}
