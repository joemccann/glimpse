import SwiftUI

struct MenuBarView: View {
    @StateObject private var sessionManager = SessionManager()
    @StateObject private var taskManager = TaskManager()
    @StateObject private var fileWatcher: FileWatcher

    @State private var selectedTask: Task?
    @State private var searchText = ""
    @State private var sessionToDelete: Session?
    @State private var showSessionList = false
    @State private var showCleanupConfirmation = false
    @AppStorage("orphanAgeDays") private var orphanAgeDays = 30

    @Environment(\.colorScheme) var colorScheme

    init() {
        let claudeDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude").path
        _fileWatcher = StateObject(wrappedValue: FileWatcher(path: claudeDir + "/tasks"))
    }

    private var bgDeep: Color {
        colorScheme == .dark ? Theme.darkBgDeep : Theme.lightBgDeep
    }

    private var bgSurface: Color {
        colorScheme == .dark ? Theme.darkBgSurface : Theme.lightBgSurface
    }

    private var bgElevated: Color {
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

    private var orphanCount: Int {
        sessionManager.sessions.filter { $0.isOrphan(ageDays: orphanAgeDays) }.count
    }

    private var currentTasks: [Task] {
        var tasks: [Task]
        if let sessionId = sessionManager.selectedSessionId {
            tasks = taskManager.loadTasks(sessionId: sessionId)
        } else if sessionManager.selectedProjectId != nil {
            // Load tasks from all sessions in the selected project
            tasks = sessionManager.filteredSessions.flatMap { session in
                taskManager.loadTasks(sessionId: session.id)
            }
        } else {
            tasks = taskManager.loadAllTasks()
        }

        if searchText.isEmpty {
            return tasks
        }

        return tasks.filter {
            $0.subject.localizedCaseInsensitiveContains(searchText) ||
            ($0.description?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    private var selectedSessionName: String {
        if let id = sessionManager.selectedSessionId,
           let session = sessionManager.filteredSessions.first(where: { $0.id == id }) {
            return session.displayName
        }
        return "All Sessions"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "diamond.fill")
                        .foregroundColor(Theme.accent)
                    Text("Glimpse")
                        .font(.headline)
                        .foregroundColor(textPrimary)
                    Spacer()

                    // Active indicator
                    if sessionManager.sessions.contains(where: { $0.hasActiveTasks }) {
                        Circle()
                            .fill(Theme.success)
                            .frame(width: 8, height: 8)
                    }
                }

                // Project picker (with built-in dropdown)
                ProjectPickerView()
                    .environmentObject(sessionManager)

                // Session picker button
                Button(action: {
                    showSessionList.toggle()
                }) {
                    HStack {
                        Text(selectedSessionName)
                            .foregroundColor(textPrimary)
                        Spacer()
                        Image(systemName: showSessionList ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(textSecondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(bgElevated)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(borderColor, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                // Session list dropdown
                if showSessionList {
                    SessionListView(
                        sessions: sessionManager.filteredSessions,
                        selectedSessionId: Binding(
                            get: { sessionManager.selectedSessionId },
                            set: { sessionManager.selectedSessionId = $0 }
                        ),
                        onSelect: { showSessionList = false },
                        onDelete: { session in
                            sessionToDelete = session
                        }
                    )
                }

                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(textSecondary)
                    TextField("Search tasks...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(6)
                .background(bgElevated)
                .cornerRadius(6)
            }
            .padding()
            .background(bgSurface)

            // Kanban board
            KanbanView(tasks: currentTasks) { task in
                selectedTask = task
            }

            // Footer
            HStack {
                Button("Quit") {
                    NSApp.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundColor(textPrimary)

                Spacer()

                // Active sessions indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(sessionManager.sessions.contains(where: { $0.hasActiveTasks }) ? Theme.success : textSecondary)
                        .frame(width: 8, height: 8)
                    Text("\(sessionManager.sessions.count) sessions")
                        .font(.caption)
                        .foregroundColor(textSecondary)
                }

                Spacer()

                HStack(spacing: 12) {
                    // Cleanup orphans button
                    Button(action: {
                        if orphanCount > 0 {
                            showCleanupConfirmation = true
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.system(size: 13))
                            if orphanCount > 0 {
                                Text("\(orphanCount)")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                        }
                        .foregroundColor(orphanCount > 0 ? Theme.warning : textSecondary.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    .help(orphanCount > 0 ? "Cleanup \(orphanCount) orphan session(s)" : "No orphan sessions")
                    .disabled(orphanCount == 0)

                    // Preferences button
                    Button(action: {
                        AppDelegate.shared?.openPreferences()
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 14))
                            .foregroundColor(textSecondary)
                    }
                    .buttonStyle(.plain)
                    .help("Preferences")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(bgSurface)
        }
        .frame(width: 800, height: 750)
        .background(bgDeep)
        .onAppear {
            sessionManager.loadSessions()
            fileWatcher.start {
                sessionManager.loadSessions()
            }
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailView(
                task: task,
                onAddNote: { note in
                    if let sessionId = task.sessionId ?? sessionManager.selectedSessionId {
                        try? taskManager.addNote(sessionId: sessionId, taskId: task.id, note: note)
                        sessionManager.loadSessions()
                    }
                },
                onDismiss: { selectedTask = nil }
            )
        }
        .sheet(item: $sessionToDelete) { session in
            DeleteConfirmationView(
                session: session,
                onConfirm: {
                    deleteSession(session)
                    sessionToDelete = nil
                },
                onCancel: {
                    sessionToDelete = nil
                }
            )
        }
        .alert("Cleanup Orphan Sessions", isPresented: $showCleanupConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete \(orphanCount) Sessions", role: .destructive) {
                performCleanup()
            }
        } message: {
            Text("This will permanently delete \(orphanCount) orphan session(s) including empty sessions, completed sessions, and sessions older than \(orphanAgeDays) days.")
        }
    }

    private func performCleanup() {
        let deleted = sessionManager.deleteOrphanSessions(ageDays: orphanAgeDays)
        print("Cleaned up \(deleted) orphan session(s)")
    }

    private func deleteSession(_ session: Session) {
        do {
            try sessionManager.deleteSession(sessionId: session.id)
            // If we deleted the selected session, reset to all sessions
            if sessionManager.selectedSessionId == session.id {
                sessionManager.selectedSessionId = nil
            }
        } catch {
            print("Failed to delete session: \(error)")
        }
    }
}

// MARK: - Session List View

struct SessionListView: View {
    let sessions: [Session]
    @Binding var selectedSessionId: String?
    let onSelect: () -> Void
    let onDelete: (Session) -> Void

    @Environment(\.colorScheme) var colorScheme

    private var bgElevated: Color {
        colorScheme == .dark ? Theme.darkBgElevated : Theme.lightBgElevated
    }

    private var borderColor: Color {
        colorScheme == .dark ? Theme.darkBorder : Theme.lightBorder
    }

    private var textPrimary: Color {
        colorScheme == .dark ? Theme.darkTextPrimary : Theme.lightTextPrimary
    }

    var body: some View {
        VStack(spacing: 0) {
            // "All Sessions" option
            AllSessionsRow(
                isSelected: selectedSessionId == nil,
                onSelect: {
                    selectedSessionId = nil
                    onSelect()
                }
            )

            Divider()
                .padding(.vertical, 4)

            // Session list
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(sessions) { session in
                        SessionRowView(
                            session: session,
                            isSelected: selectedSessionId == session.id,
                            onSelect: {
                                selectedSessionId = session.id
                                onSelect()
                            },
                            onDelete: {
                                onDelete(session)
                            }
                        )
                    }
                }
            }
            .frame(maxHeight: 300)
        }
        .padding(8)
        .background(bgElevated)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: 1)
        )
    }
}

// MARK: - All Sessions Row

struct AllSessionsRow: View {
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovering = false
    @Environment(\.colorScheme) var colorScheme

    private var textPrimary: Color {
        colorScheme == .dark ? Theme.darkTextPrimary : Theme.lightTextPrimary
    }

    private var bgHover: Color {
        colorScheme == .dark ? Theme.darkBgHover : Theme.lightBgHover
    }

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isSelected ? Theme.accent : Color.clear)
                .frame(width: 6, height: 6)

            Text("All Sessions")
                .font(.subheadline)
                .foregroundColor(textPrimary)

            Spacer()
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
