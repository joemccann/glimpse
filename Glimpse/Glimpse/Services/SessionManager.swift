import Foundation
import Combine

class SessionManager: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var projects: [Project] = []
    @Published var selectedProjectId: String?
    @Published var selectedSessionId: String?

    /// Sessions filtered by selected project (or all if no project selected)
    var filteredSessions: [Session] {
        guard let projectId = selectedProjectId else {
            return sessions
        }
        return sessions.filter { $0.project == projectPath(for: projectId) }
    }

    /// Get the actual path for a project ID
    private func projectPath(for projectId: String) -> String {
        "/" + projectId.replacingOccurrences(of: "-", with: "/")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    private let claudeDirectory: String
    private let fileManager = FileManager.default

    var tasksDirectory: String {
        (claudeDirectory as NSString).appendingPathComponent("tasks")
    }

    var projectsDirectory: String {
        (claudeDirectory as NSString).appendingPathComponent("projects")
    }

    init(claudeDirectory: String? = nil) {
        self.claudeDirectory = claudeDirectory ??
            fileManager.homeDirectoryForCurrentUser
                .appendingPathComponent(".claude").path
    }

    func loadSessions() {
        guard fileManager.fileExists(atPath: tasksDirectory) else {
            sessions = []
            return
        }

        do {
            let metadata = loadSessionMetadata()
            let entries = try fileManager.contentsOfDirectory(atPath: tasksDirectory)
            var loadedSessions: [Session] = []

            for entry in entries {
                let sessionPath = (tasksDirectory as NSString).appendingPathComponent(entry)
                var isDirectory: ObjCBool = false

                guard fileManager.fileExists(atPath: sessionPath, isDirectory: &isDirectory),
                      isDirectory.boolValue else { continue }

                let taskFiles = try fileManager.contentsOfDirectory(atPath: sessionPath)
                    .filter { $0.hasSuffix(".json") }

                var completed = 0, inProgress = 0, pending = 0

                for file in taskFiles {
                    let filePath = (sessionPath as NSString).appendingPathComponent(file)
                    if let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
                       let task = try? JSONDecoder().decode(Task.self, from: data) {
                        switch task.status {
                        case .completed: completed += 1
                        case .inProgress: inProgress += 1
                        case .pending: pending += 1
                        }
                    }
                }

                let attrs = try fileManager.attributesOfItem(atPath: sessionPath)
                let modifiedAt = attrs[.modificationDate] as? Date ?? Date()

                let meta = metadata[entry]

                // A session has a matching project if its ID appears in the metadata
                // (which is populated from .jsonl files in the projects directory)
                let hasMatchingProject = meta != nil

                loadedSessions.append(Session(
                    id: entry,
                    name: meta?.customTitle,
                    slug: meta?.slug,
                    project: meta?.project,
                    gitBranch: meta?.gitBranch,
                    taskCount: taskFiles.count,
                    completed: completed,
                    inProgress: inProgress,
                    pending: pending,
                    modifiedAt: modifiedAt,
                    hasMatchingProject: hasMatchingProject
                ))
            }

            sessions = loadedSessions.sorted { $0.modifiedAt > $1.modifiedAt }
            loadProjects()
        } catch {
            print("Error loading sessions: \(error)")
            sessions = []
        }
    }

    /// Load projects by grouping sessions by their project path
    func loadProjects() {
        var projectMap: [String: Project] = [:]

        guard fileManager.fileExists(atPath: projectsDirectory) else {
            projects = []
            return
        }

        do {
            let projectDirs = try fileManager.contentsOfDirectory(atPath: projectsDirectory)

            for projectDir in projectDirs {
                let projectPath = (projectsDirectory as NSString).appendingPathComponent(projectDir)
                var isDirectory: ObjCBool = false

                guard fileManager.fileExists(atPath: projectPath, isDirectory: &isDirectory),
                      isDirectory.boolValue else { continue }

                // Convert encoded dir name back to path
                let actualPath = "/" + projectDir.replacingOccurrences(of: "-", with: "/")
                    .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

                // Find sessions belonging to this project
                let projectSessions = sessions.filter { $0.project == actualPath }

                // Only include projects that have sessions with tasks
                if !projectSessions.isEmpty {
                    projectMap[projectDir] = Project(
                        id: projectDir,
                        path: actualPath,
                        sessions: projectSessions
                    )
                }
            }

            // Sort projects by most recent activity
            projects = projectMap.values.sorted {
                ($0.lastModified ?? .distantPast) > ($1.lastModified ?? .distantPast)
            }
        } catch {
            print("Error loading projects: \(error)")
            projects = []
        }
    }

    /// Select a project and optionally reset session selection
    func selectProject(_ projectId: String?) {
        selectedProjectId = projectId
        // Reset session selection when project changes
        if selectedSessionId != nil {
            // Check if selected session is still in filtered list
            if let sessionId = selectedSessionId,
               !filteredSessions.contains(where: { $0.id == sessionId }) {
                selectedSessionId = nil
            }
        }
    }

    func deleteSession(sessionId: String) throws {
        let sessionPath = (tasksDirectory as NSString).appendingPathComponent(sessionId)

        guard fileManager.fileExists(atPath: sessionPath) else {
            throw NSError(domain: "SessionManager", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Session folder not found"
            ])
        }

        try fileManager.removeItem(atPath: sessionPath)

        // Refresh the sessions list
        loadSessions()
    }

    /// Delete all orphan sessions (stale, no project, or completed)
    /// - Parameter ageDays: Age threshold in days for stale sessions
    /// - Returns: Number of sessions deleted
    @discardableResult
    func deleteOrphanSessions(ageDays: Int = Session.defaultOrphanAgeDays) -> Int {
        let orphans = sessions.filter { $0.isOrphan(ageDays: ageDays) }
        var deletedCount = 0

        for session in orphans {
            do {
                let sessionPath = (tasksDirectory as NSString).appendingPathComponent(session.id)
                try fileManager.removeItem(atPath: sessionPath)
                deletedCount += 1
            } catch {
                print("Failed to delete orphan session \(session.id): \(error)")
            }
        }

        if deletedCount > 0 {
            loadSessions()
        }

        return deletedCount
    }

    /// Delete all sessions where all tasks are completed
    /// - Returns: Number of sessions deleted
    @discardableResult
    func deleteCompletedSessions() -> Int {
        let completed = sessions.filter { $0.isAllCompleted }
        var deletedCount = 0

        for session in completed {
            do {
                let sessionPath = (tasksDirectory as NSString).appendingPathComponent(session.id)
                try fileManager.removeItem(atPath: sessionPath)
                deletedCount += 1
            } catch {
                print("Failed to delete completed session \(session.id): \(error)")
            }
        }

        if deletedCount > 0 {
            loadSessions()
        }

        return deletedCount
    }

    /// Count of orphan sessions
    func orphanCount(ageDays: Int = Session.defaultOrphanAgeDays) -> Int {
        sessions.filter { $0.isOrphan(ageDays: ageDays) }.count
    }

    /// Count of completed sessions
    var completedSessionCount: Int {
        sessions.filter { $0.isAllCompleted }.count
    }

    private func loadSessionMetadata() -> [String: SessionMetadata] {
        var metadata: [String: SessionMetadata] = [:]

        guard fileManager.fileExists(atPath: projectsDirectory) else {
            return metadata
        }

        do {
            let projectDirs = try fileManager.contentsOfDirectory(atPath: projectsDirectory)

            for projectDir in projectDirs {
                let projectPath = (projectsDirectory as NSString).appendingPathComponent(projectDir)
                var isDirectory: ObjCBool = false

                guard fileManager.fileExists(atPath: projectPath, isDirectory: &isDirectory),
                      isDirectory.boolValue else { continue }

                let files = try fileManager.contentsOfDirectory(atPath: projectPath)
                    .filter { $0.hasSuffix(".jsonl") }

                let projectName = "/" + projectDir.replacingOccurrences(of: "-", with: "/")
                    .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

                for file in files {
                    let sessionId = file.replacingOccurrences(of: ".jsonl", with: "")
                    let jsonlPath = (projectPath as NSString).appendingPathComponent(file)
                    let info = readSessionInfoFromJsonl(path: jsonlPath)

                    metadata[sessionId] = SessionMetadata(
                        customTitle: info.customTitle,
                        slug: info.slug,
                        project: projectName,
                        gitBranch: nil
                    )
                }

                // Check sessions-index.json for additional metadata
                let indexPath = (projectPath as NSString).appendingPathComponent("sessions-index.json")
                if fileManager.fileExists(atPath: indexPath),
                   let data = try? Data(contentsOf: URL(fileURLWithPath: indexPath)),
                   let index = try? JSONDecoder().decode(SessionsIndex.self, from: data) {
                    for entry in index.entries {
                        if var existing = metadata[entry.sessionId] {
                            existing.gitBranch = entry.gitBranch
                            if let name = entry.customName ?? entry.name {
                                existing.customTitle = name
                            }
                            metadata[entry.sessionId] = existing
                        }
                    }
                }
            }
        } catch {
            print("Error loading session metadata: \(error)")
        }

        return metadata
    }

    private func readSessionInfoFromJsonl(path: String) -> (customTitle: String?, slug: String?) {
        var customTitle: String?
        var slug: String?

        guard let handle = FileHandle(forReadingAtPath: path) else {
            return (nil, nil)
        }
        defer { try? handle.close() }

        let data = handle.readData(ofLength: 65536)
        guard let content = String(data: data, encoding: .utf8) else {
            return (nil, nil)
        }

        for line in content.split(separator: "\n") {
            guard let lineData = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any] else {
                continue
            }

            if let type = json["type"] as? String, type == "custom-title",
               let title = json["customTitle"] as? String {
                customTitle = title
            }

            if slug == nil, let s = json["slug"] as? String {
                slug = s
            }

            if customTitle != nil && slug != nil { break }
        }

        return (customTitle, slug)
    }
}

private struct SessionMetadata {
    var customTitle: String?
    var slug: String?
    var project: String?
    var gitBranch: String?
}

private struct SessionsIndex: Codable {
    let entries: [SessionIndexEntry]
}

private struct SessionIndexEntry: Codable {
    let sessionId: String
    var customName: String?
    var name: String?
    var gitBranch: String?
}
