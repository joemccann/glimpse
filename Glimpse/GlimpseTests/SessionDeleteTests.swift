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

    // MARK: - Empty Session Tests

    func testEmptySessionIsOrphan() throws {
        // Create a session with NO tasks but with a matching project
        let tasksDir = tempDir.appendingPathComponent("tasks")
        let sessionDir = tasksDir.appendingPathComponent("empty-session")
        try FileManager.default.createDirectory(at: sessionDir, withIntermediateDirectories: true)

        // Create matching project so isEmpty is the only orphan reason
        let projectDir = tempDir.appendingPathComponent("projects/-test-project")
        try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)
        try """
        {"type":"custom-title","customTitle":"Empty Project"}
        """.write(to: projectDir.appendingPathComponent("empty-session.jsonl"), atomically: true, encoding: .utf8)

        sessionManager.loadSessions()

        guard let session = sessionManager.sessions.first(where: { $0.id == "empty-session" }) else {
            XCTFail("Session not found")
            return
        }

        XCTAssertTrue(session.isEmpty)
        XCTAssertTrue(session.isOrphan)
        XCTAssertEqual(session.orphanReason, "No tasks")
    }

    // MARK: - Bulk Cleanup Tests

    func testDeleteOrphanSessions() throws {
        let tasksDir = tempDir.appendingPathComponent("tasks")

        // Create an orphan (empty) session
        let emptySession = tasksDir.appendingPathComponent("empty-orphan")
        try FileManager.default.createDirectory(at: emptySession, withIntermediateDirectories: true)

        // Create an orphan (all completed) session
        let completedSession = tasksDir.appendingPathComponent("completed-orphan")
        try FileManager.default.createDirectory(at: completedSession, withIntermediateDirectories: true)
        try """
        {"id": "1", "subject": "Done", "status": "completed"}
        """.write(to: completedSession.appendingPathComponent("1.json"), atomically: true, encoding: .utf8)

        // Create a non-orphan (pending task, has project) session
        let activeSession = tasksDir.appendingPathComponent("active-session")
        try FileManager.default.createDirectory(at: activeSession, withIntermediateDirectories: true)
        try """
        {"id": "1", "subject": "Active", "status": "in_progress"}
        """.write(to: activeSession.appendingPathComponent("1.json"), atomically: true, encoding: .utf8)

        // Create matching project for active session
        let projectDir = tempDir.appendingPathComponent("projects/-test-project")
        try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)
        try """
        {"type":"custom-title","customTitle":"Active"}
        """.write(to: projectDir.appendingPathComponent("active-session.jsonl"), atomically: true, encoding: .utf8)

        sessionManager.loadSessions()

        // Verify initial state
        XCTAssertEqual(sessionManager.sessions.count, 3)
        XCTAssertEqual(sessionManager.orphanCount(), 2) // empty + completed

        // Delete orphans
        let deleted = sessionManager.deleteOrphanSessions()

        XCTAssertEqual(deleted, 2)
        XCTAssertEqual(sessionManager.sessions.count, 1)
        XCTAssertEqual(sessionManager.sessions.first?.id, "active-session")
    }

    func testDeleteCompletedSessions() throws {
        let tasksDir = tempDir.appendingPathComponent("tasks")

        // Create completed session
        let completedSession = tasksDir.appendingPathComponent("completed-1")
        try FileManager.default.createDirectory(at: completedSession, withIntermediateDirectories: true)
        try """
        {"id": "1", "subject": "Done", "status": "completed"}
        """.write(to: completedSession.appendingPathComponent("1.json"), atomically: true, encoding: .utf8)

        // Create in-progress session
        let activeSession = tasksDir.appendingPathComponent("active-1")
        try FileManager.default.createDirectory(at: activeSession, withIntermediateDirectories: true)
        try """
        {"id": "1", "subject": "Working", "status": "in_progress"}
        """.write(to: activeSession.appendingPathComponent("1.json"), atomically: true, encoding: .utf8)

        sessionManager.loadSessions()
        XCTAssertEqual(sessionManager.completedSessionCount, 1)

        let deleted = sessionManager.deleteCompletedSessions()

        XCTAssertEqual(deleted, 1)
        XCTAssertEqual(sessionManager.sessions.count, 1)
        XCTAssertEqual(sessionManager.sessions.first?.id, "active-1")
    }

    func testOrphanCountWithConfigurableAge() throws {
        let tasksDir = tempDir.appendingPathComponent("tasks")

        // Create a session (will be recent, so not age-orphaned)
        let recentSession = tasksDir.appendingPathComponent("recent-session")
        try FileManager.default.createDirectory(at: recentSession, withIntermediateDirectories: true)
        try """
        {"id": "1", "subject": "Test", "status": "pending"}
        """.write(to: recentSession.appendingPathComponent("1.json"), atomically: true, encoding: .utf8)

        sessionManager.loadSessions()

        // With default age (30 days), session is orphan because no project
        XCTAssertEqual(sessionManager.orphanCount(ageDays: 30), 1)

        // Session should still be orphan at any age because it has no project
        XCTAssertEqual(sessionManager.orphanCount(ageDays: 7), 1)
    }
}
