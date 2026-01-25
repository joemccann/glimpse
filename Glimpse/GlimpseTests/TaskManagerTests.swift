import XCTest
@testable import Glimpse

final class TaskManagerTests: XCTestCase {
    var taskManager: TaskManager!
    var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        taskManager = TaskManager(tasksDirectory: tempDir.path)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    func testLoadTasksFromSession() throws {
        // Create session directory
        let sessionDir = tempDir.appendingPathComponent("session-123")
        try FileManager.default.createDirectory(at: sessionDir, withIntermediateDirectories: true)

        // Create task file
        let taskJSON = """
        {"id": "1", "subject": "Test task", "status": "pending"}
        """
        try taskJSON.write(to: sessionDir.appendingPathComponent("1.json"), atomically: true, encoding: .utf8)

        let tasks = taskManager.loadTasks(sessionId: "session-123")

        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.subject, "Test task")
    }
}
