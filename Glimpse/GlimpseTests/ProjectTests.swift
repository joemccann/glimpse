import XCTest
@testable import Glimpse

final class ProjectTests: XCTestCase {

    // MARK: - displayName Tests

    func testDisplayNameExtractsFolderNameFromPath() {
        let project = Project(
            id: "-Users-joe-dev-apps-glimpse",
            path: "/Users/joe/dev/apps/glimpse",
            sessions: []
        )

        XCTAssertEqual(project.displayName, "glimpse")
    }

    func testDisplayNameWithNestedPath() {
        let project = Project(
            id: "-Users-joe-dev-apps-my-project",
            path: "/Users/joe/dev/apps/my-project",
            sessions: []
        )

        XCTAssertEqual(project.displayName, "my-project")
    }

    func testDisplayNameWithRootPath() {
        let project = Project(
            id: "-tmp",
            path: "/tmp",
            sessions: []
        )

        XCTAssertEqual(project.displayName, "tmp")
    }

    // MARK: - totalTaskCount Tests

    func testTotalTaskCountSumsAcrossSessions() {
        let session1 = Session(
            id: "session-1",
            taskCount: 5,
            completed: 2,
            inProgress: 1,
            pending: 2,
            modifiedAt: Date()
        )
        let session2 = Session(
            id: "session-2",
            taskCount: 3,
            completed: 1,
            inProgress: 2,
            pending: 0,
            modifiedAt: Date()
        )
        let project = Project(
            id: "-Users-joe-dev-project",
            path: "/Users/joe/dev/project",
            sessions: [session1, session2]
        )

        XCTAssertEqual(project.totalTaskCount, 8)
    }

    func testTotalTaskCountWithNoSessions() {
        let project = Project(
            id: "-Users-joe-dev-project",
            path: "/Users/joe/dev/project",
            sessions: []
        )

        XCTAssertEqual(project.totalTaskCount, 0)
    }

    func testTotalTaskCountWithSingleSession() {
        let session = Session(
            id: "session-1",
            taskCount: 10,
            completed: 5,
            inProgress: 3,
            pending: 2,
            modifiedAt: Date()
        )
        let project = Project(
            id: "-Users-joe-dev-project",
            path: "/Users/joe/dev/project",
            sessions: [session]
        )

        XCTAssertEqual(project.totalTaskCount, 10)
    }

    // MARK: - hasActiveTasks Tests

    func testHasActiveTasksIsTrueWhenAnySessionHasActiveTasks() {
        let inactiveSession = Session(
            id: "session-1",
            taskCount: 5,
            completed: 5,
            inProgress: 0,
            pending: 0,
            modifiedAt: Date()
        )
        let activeSession = Session(
            id: "session-2",
            taskCount: 3,
            completed: 1,
            inProgress: 2,
            pending: 0,
            modifiedAt: Date()
        )
        let project = Project(
            id: "-Users-joe-dev-project",
            path: "/Users/joe/dev/project",
            sessions: [inactiveSession, activeSession]
        )

        XCTAssertTrue(project.hasActiveTasks)
    }

    func testHasActiveTasksIsFalseWhenNoSessionsHaveActiveTasks() {
        let session1 = Session(
            id: "session-1",
            taskCount: 5,
            completed: 5,
            inProgress: 0,
            pending: 0,
            modifiedAt: Date()
        )
        let session2 = Session(
            id: "session-2",
            taskCount: 3,
            completed: 3,
            inProgress: 0,
            pending: 0,
            modifiedAt: Date()
        )
        let project = Project(
            id: "-Users-joe-dev-project",
            path: "/Users/joe/dev/project",
            sessions: [session1, session2]
        )

        XCTAssertFalse(project.hasActiveTasks)
    }

    func testHasActiveTasksIsFalseWithNoSessions() {
        let project = Project(
            id: "-Users-joe-dev-project",
            path: "/Users/joe/dev/project",
            sessions: []
        )

        XCTAssertFalse(project.hasActiveTasks)
    }

    // MARK: - activeTaskCount Tests

    func testActiveTaskCountSumsInProgressAcrossSessions() {
        let session1 = Session(
            id: "session-1",
            taskCount: 5,
            completed: 2,
            inProgress: 2,
            pending: 1,
            modifiedAt: Date()
        )
        let session2 = Session(
            id: "session-2",
            taskCount: 3,
            completed: 1,
            inProgress: 1,
            pending: 1,
            modifiedAt: Date()
        )
        let project = Project(
            id: "-Users-joe-dev-project",
            path: "/Users/joe/dev/project",
            sessions: [session1, session2]
        )

        XCTAssertEqual(project.activeTaskCount, 3)
    }
}
