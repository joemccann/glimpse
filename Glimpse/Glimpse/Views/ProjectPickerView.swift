import SwiftUI

struct ProjectPickerView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @Environment(\.colorScheme) var colorScheme

    @State private var isExpanded = false
    @State private var hoveredProjectId: String?

    private var textPrimary: Color {
        colorScheme == .dark ? Theme.darkTextPrimary : Theme.lightTextPrimary
    }

    private var textSecondary: Color {
        colorScheme == .dark ? Theme.darkTextSecondary : Theme.lightTextSecondary
    }

    private var bgSurface: Color {
        colorScheme == .dark ? Theme.darkBgSurface : Theme.lightBgSurface
    }

    private var bgElevated: Color {
        colorScheme == .dark ? Theme.darkBgElevated : Theme.lightBgElevated
    }

    private var bgHover: Color {
        colorScheme == .dark ? Theme.darkBgHover : Theme.lightBgHover
    }

    private var border: Color {
        colorScheme == .dark ? Theme.darkBorder : Theme.lightBorder
    }

    /// Currently selected project display text
    private var selectedDisplayText: String {
        if let projectId = sessionManager.selectedProjectId,
           let project = sessionManager.projects.first(where: { $0.id == projectId }) {
            return project.displayName
        }
        return "All Projects"
    }

    /// Whether the currently selected project has active tasks
    private var selectedHasActiveTasks: Bool {
        if let projectId = sessionManager.selectedProjectId,
           let project = sessionManager.projects.first(where: { $0.id == projectId }) {
            return project.hasActiveTasks
        }
        // For "All Projects", check if any session has active tasks
        return sessionManager.sessions.contains { $0.hasActiveTasks }
    }

    /// Task count for the currently selected project
    private var selectedTaskCount: Int {
        if let projectId = sessionManager.selectedProjectId,
           let project = sessionManager.projects.first(where: { $0.id == projectId }) {
            return project.totalTaskCount
        }
        // For "All Projects", count all tasks
        return sessionManager.sessions.reduce(0) { $0 + $1.taskCount }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Dropdown button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 8) {
                    // Active indicator
                    if selectedHasActiveTasks {
                        Circle()
                            .fill(Theme.success)
                            .frame(width: 6, height: 6)
                    }

                    Text(selectedDisplayText)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(textPrimary)
                        .lineLimit(1)

                    Spacer()

                    // Task count badge
                    Text("\(selectedTaskCount)")
                        .font(.caption)
                        .foregroundColor(textSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(bgElevated)
                        .cornerRadius(4)

                    // Chevron
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(textSecondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(bgSurface)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(border, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            // Dropdown menu
            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    // "All Projects" option
                    ProjectPickerRow(
                        displayName: "All Projects",
                        taskCount: sessionManager.sessions.reduce(0) { $0 + $1.taskCount },
                        hasActiveTasks: sessionManager.sessions.contains { $0.hasActiveTasks },
                        isSelected: sessionManager.selectedProjectId == nil,
                        isHovered: hoveredProjectId == "all",
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        bgHover: bgHover
                    )
                    .onHover { hovering in
                        hoveredProjectId = hovering ? "all" : nil
                    }
                    .onTapGesture {
                        sessionManager.selectProject(nil)
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isExpanded = false
                        }
                    }

                    Divider()
                        .background(border)
                        .padding(.vertical, 4)

                    // Project list
                    ForEach(sessionManager.projects) { project in
                        ProjectPickerRow(
                            displayName: project.displayName,
                            taskCount: project.totalTaskCount,
                            hasActiveTasks: project.hasActiveTasks,
                            isSelected: sessionManager.selectedProjectId == project.id,
                            isHovered: hoveredProjectId == project.id,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            bgHover: bgHover
                        )
                        .onHover { hovering in
                            hoveredProjectId = hovering ? project.id : nil
                        }
                        .onTapGesture {
                            sessionManager.selectProject(project.id)
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isExpanded = false
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
                .background(bgSurface)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(border, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                .padding(.top, 4)
            }
        }
    }
}

/// Individual row in the project picker dropdown
private struct ProjectPickerRow: View {
    let displayName: String
    let taskCount: Int
    let hasActiveTasks: Bool
    let isSelected: Bool
    let isHovered: Bool
    let textPrimary: Color
    let textSecondary: Color
    let bgHover: Color

    var body: some View {
        HStack(spacing: 8) {
            // Selection indicator
            Circle()
                .fill(isSelected ? Theme.accent : Color.clear)
                .frame(width: 6, height: 6)

            // Active task indicator (green dot)
            if hasActiveTasks {
                Circle()
                    .fill(Theme.success)
                    .frame(width: 5, height: 5)
            }

            Text(displayName)
                .font(.subheadline)
                .foregroundColor(textPrimary)
                .lineLimit(1)

            Spacer()

            // Task count badge
            Text("\(taskCount)")
                .font(.caption)
                .foregroundColor(textSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isHovered ? bgHover : Color.clear)
        .cornerRadius(6)
        .contentShape(Rectangle())
    }
}

#Preview {
    ProjectPickerView()
        .environmentObject(SessionManager())
        .padding()
        .frame(width: 280)
        .preferredColorScheme(.dark)
}
