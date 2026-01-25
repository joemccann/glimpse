import Foundation
import Combine

class TaskManager: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var activeTasks: [Task] = []

    private let tasksDirectory: String
    private let fileManager = FileManager.default

    init(tasksDirectory: String? = nil) {
        self.tasksDirectory = tasksDirectory ??
            fileManager.homeDirectoryForCurrentUser
                .appendingPathComponent(".claude/tasks").path
    }

    func loadTasks(sessionId: String) -> [Task] {
        let sessionPath = (tasksDirectory as NSString).appendingPathComponent(sessionId)

        guard fileManager.fileExists(atPath: sessionPath) else {
            return []
        }

        do {
            let files = try fileManager.contentsOfDirectory(atPath: sessionPath)
                .filter { $0.hasSuffix(".json") }

            var tasks: [Task] = []
            for file in files {
                let filePath = (sessionPath as NSString).appendingPathComponent(file)
                let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
                var task = try JSONDecoder().decode(Task.self, from: data)
                task.sessionId = sessionId
                tasks.append(task)
            }

            return tasks.sorted {
                (Int($0.id) ?? 0) < (Int($1.id) ?? 0)
            }
        } catch {
            print("Error loading tasks: \(error)")
            return []
        }
    }

    func loadAllTasks() -> [Task] {
        guard fileManager.fileExists(atPath: tasksDirectory) else {
            return []
        }

        do {
            let sessionDirs = try fileManager.contentsOfDirectory(atPath: tasksDirectory)
            var allTasks: [Task] = []

            for sessionId in sessionDirs {
                let sessionTasks = loadTasks(sessionId: sessionId)
                allTasks.append(contentsOf: sessionTasks)
            }

            return allTasks
        } catch {
            print("Error loading all tasks: \(error)")
            return []
        }
    }

    func addNote(sessionId: String, taskId: String, note: String) throws {
        let sessionPath = (tasksDirectory as NSString).appendingPathComponent(sessionId)
        let filePath = (sessionPath as NSString).appendingPathComponent("\(taskId).json")

        let url = URL(fileURLWithPath: filePath)
        let data = try Data(contentsOf: url)
        var task = try JSONDecoder().decode(Task.self, from: data)

        let noteBlock = "\n\n---\n\n#### [Note added by user]\n\n\(note.trimmingCharacters(in: .whitespacesAndNewlines))"
        task.description = (task.description ?? "") + noteBlock

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let updatedData = try encoder.encode(task)
        try updatedData.write(to: url)
    }
}
