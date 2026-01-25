import XCTest
@testable import Glimpse

final class SessionDeleteTests: XCTestCase {
    var sessionManager: SessionManager!
    var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)

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

    func testDeleteSessionRemovesFolder() throws {
        // Create a session with tasks
        let tasksDir = tempDir.appendingPathComponent("tasks")
        let sessionDir = tasksDir.appendingPathComponent("test-session-123")
        try FileManager.default.createDirectory(at: sessionDir, withIntermediateDirectories: true)

        let taskJSON = """
        {"id": "1", "subject": "Test", "status": "pending"}
        """
        try taskJSON.write(to: sessionDir.appendingPathComponent("1.json"), atomically: true, encoding: .utf8)

        // Verify session exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: sessionDir.path))

        // Delete the session
        try sessionManager.deleteSession(sessionId: "test-session-123")

        // Verify session is gone
        XCTAssertFalse(FileManager.default.fileExists(atPath: sessionDir.path))
    }

    func testOrphanDetectionNoProject() throws {
        // Create a session without matching project
        let tasksDir = tempDir.appendingPathComponent("tasks")
        let sessionDir = tasksDir.appendingPathComponent("orphan-session")
        try FileManager.default.createDirectory(at: sessionDir, withIntermediateDirectories: true)

        let taskJSON = """
        {"id": "1", "subject": "Test", "status": "pending"}
        """
        try taskJSON.write(to: sessionDir.appendingPathComponent("1.json"), atomically: true, encoding: .utf8)

        sessionManager.loadSessions()

        guard let session = sessionManager.sessions.first(where: { $0.id == "orphan-session" }) else {
            XCTFail("Session not found")
            return
        }

        // Should be orphan because no matching project
        XCTAssertFalse(session.hasMatchingProject)
        XCTAssertTrue(session.isOrphan)
    }

    func testOrphanDetectionAllCompleted() throws {
        // Create a session with all completed tasks
        let tasksDir = tempDir.appendingPathComponent("tasks")
        let sessionDir = tasksDir.appendingPathComponent("completed-session")
        try FileManager.default.createDirectory(at: sessionDir, withIntermediateDirectories: true)

        let taskJSON = """
        {"id": "1", "subject": "Test", "status": "completed"}
        """
        try taskJSON.write(to: sessionDir.appendingPathComponent("1.json"), atomically: true, encoding: .utf8)

        sessionManager.loadSessions()

        guard let session = sessionManager.sessions.first(where: { $0.id == "completed-session" }) else {
            XCTFail("Session not found")
            return
        }

        XCTAssertTrue(session.isAllCompleted)
        XCTAssertTrue(session.isOrphan)
    }

    func testDeleteNonExistentSessionThrows() {
        XCTAssertThrowsError(try sessionManager.deleteSession(sessionId: "non-existent")) { error in
            XCTAssertNotNil(error)
        }
    }
}
