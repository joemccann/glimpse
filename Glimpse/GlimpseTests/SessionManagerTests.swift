import XCTest
@testable import Glimpse

final class SessionManagerTests: XCTestCase {
    var sessionManager: SessionManager!
    var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let tasksDir = tempDir.appendingPathComponent("tasks")
        let projectsDir = tempDir.appendingPathComponent("projects")
        try? FileManager.default.createDirectory(at: tasksDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: projectsDir, withIntermediateDirectories: true)

        sessionManager = SessionManager(claudeDirectory: tempDir.path)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    func testLoadSessionsFromTasksDirectory() throws {
        let tasksDir = tempDir.appendingPathComponent("tasks")
        let sessionDir = tasksDir.appendingPathComponent("abc-123")
        try FileManager.default.createDirectory(at: sessionDir, withIntermediateDirectories: true)

        let taskJSON = """
        {"id": "1", "subject": "Test", "status": "completed"}
        """
        try taskJSON.write(to: sessionDir.appendingPathComponent("1.json"), atomically: true, encoding: .utf8)

        sessionManager.loadSessions()

        XCTAssertEqual(sessionManager.sessions.count, 1)
        XCTAssertEqual(sessionManager.sessions.first?.id, "abc-123")
        XCTAssertEqual(sessionManager.sessions.first?.completed, 1)
    }
}
