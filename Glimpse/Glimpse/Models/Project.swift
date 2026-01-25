import Foundation

/// Represents a Claude Code project directory
struct Project: Identifiable, Equatable {
    let id: String           // Encoded path (e.g., "-Users-joe-dev-apps-glimpse")
    let path: String         // Full path (e.g., "/Users/joe/dev/apps/glimpse")
    var sessions: [Session]  // Sessions associated with this project

    /// Display name is the last path component (folder name)
    var displayName: String {
        // Extract folder name from path
        let url = URL(fileURLWithPath: path)
        return url.lastPathComponent
    }

    /// Count of all tasks across all sessions in this project
    var totalTaskCount: Int {
        sessions.reduce(0) { $0 + $1.taskCount }
    }

    /// Count of in-progress tasks across all sessions
    var activeTaskCount: Int {
        sessions.reduce(0) { $0 + $1.inProgress }
    }

    /// Whether any session in this project has active tasks
    var hasActiveTasks: Bool {
        sessions.contains { $0.hasActiveTasks }
    }

    /// Most recent modification date across all sessions
    var lastModified: Date? {
        sessions.map { $0.modifiedAt }.max()
    }
}
