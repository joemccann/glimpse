import SwiftUI

struct PreferencesView: View {
    @AppStorage("claudeDirectory") private var claudeDirectory = FileManager.default
        .homeDirectoryForCurrentUser.appendingPathComponent(".claude").path
    @AppStorage("notifyOnTaskComplete") private var notifyOnTaskComplete = true
    @AppStorage("notifyOnSessionComplete") private var notifyOnSessionComplete = true
    @AppStorage("notifyOnBlocked") private var notifyOnBlocked = false
    @AppStorage("theme") private var theme = "system"
    @AppStorage("autoRemoveCompletedSessions") private var autoRemoveCompletedSessions = false
    @AppStorage("orphanAgeDays") private var orphanAgeDays = 30

    @State private var cleanupMessage: String?
    @State private var showCleanupConfirmation = false
    @State private var orphanCountToDelete = 0

    private var sessionManager: SessionManager {
        SessionManager(claudeDirectory: claudeDirectory)
    }

    var body: some View {
        Form {
            Section("Claude Directory") {
                HStack {
                    TextField("Path", text: $claudeDirectory)
                        .textFieldStyle(.roundedBorder)

                    Button("Browse...") {
                        selectDirectory()
                    }
                }
            }

            Section("Notifications") {
                Toggle("Notify when task completes", isOn: $notifyOnTaskComplete)
                Toggle("Notify when session completes", isOn: $notifyOnSessionComplete)
                Toggle("Notify when task is blocked", isOn: $notifyOnBlocked)
            }

            Section("Session Cleanup") {
                Toggle("Auto-remove completed sessions on launch", isOn: $autoRemoveCompletedSessions)
                    .help("Automatically delete sessions where all tasks are completed when the app starts")

                HStack {
                    Text("Mark sessions as stale after")
                    Stepper("\(orphanAgeDays) days", value: $orphanAgeDays, in: 7...90, step: 7)
                        .frame(width: 120)
                }
                .help("Sessions older than this are considered orphaned")

                HStack {
                    Button("Cleanup Orphan Sessions...") {
                        prepareCleanup()
                    }

                    if let message = cleanupMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section("Appearance") {
                Picker("Theme", selection: $theme) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.segmented)
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 380)
        .alert("Cleanup Orphan Sessions", isPresented: $showCleanupConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete \(orphanCountToDelete) Sessions", role: .destructive) {
                performCleanup()
            }
        } message: {
            Text("This will permanently delete \(orphanCountToDelete) orphan session(s). This includes sessions that are completed, older than \(orphanAgeDays) days, or have no matching project.")
        }
    }

    private func selectDirectory() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false

        if panel.runModal() == .OK, let url = panel.url {
            claudeDirectory = url.path
        }
    }

    private func prepareCleanup() {
        let manager = sessionManager
        manager.loadSessions()
        orphanCountToDelete = manager.orphanCount(ageDays: orphanAgeDays)

        if orphanCountToDelete > 0 {
            showCleanupConfirmation = true
        } else {
            cleanupMessage = "No orphan sessions found"
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                cleanupMessage = nil
            }
        }
    }

    private func performCleanup() {
        let manager = sessionManager
        manager.loadSessions()
        let deleted = manager.deleteOrphanSessions(ageDays: orphanAgeDays)
        cleanupMessage = "Deleted \(deleted) session(s)"
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            cleanupMessage = nil
        }
    }
}
