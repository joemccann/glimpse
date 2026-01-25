import XCTest
@testable import Glimpse

final class TaskTests: XCTestCase {
    func testTaskDecodingFromJSON() throws {
        let json = """
        {
            "id": "1",
            "subject": "Implement feature X",
            "description": "Details here",
            "activeForm": "Implementing feature X",
            "status": "in_progress",
            "blocks": ["2", "3"],
            "blockedBy": []
        }
        """.data(using: .utf8)!

        let task = try JSONDecoder().decode(Task.self, from: json)

        XCTAssertEqual(task.id, "1")
        XCTAssertEqual(task.subject, "Implement feature X")
        XCTAssertEqual(task.status, .inProgress)
        XCTAssertEqual(task.blocks, ["2", "3"])
    }

    func testTaskStatusEnum() {
        XCTAssertEqual(TaskStatus.inProgress.rawValue, "in_progress")
        XCTAssertEqual(TaskStatus.pending.rawValue, "pending")
        XCTAssertEqual(TaskStatus.completed.rawValue, "completed")
    }
}
