import Foundation

enum TaskStatus: String, Codable, CaseIterable {
    case pending
    case inProgress = "in_progress"
    case completed
}

struct Task: Identifiable, Codable, Equatable {
    let id: String
    let subject: String
    var description: String?
    var activeForm: String?
    var status: TaskStatus
    var blocks: [String]?
    var blockedBy: [String]?

    // Extended properties for multi-session views
    var sessionId: String?
    var sessionName: String?
    var project: String?

    var isBlocked: Bool {
        guard let blockedBy = blockedBy else { return false }
        return !blockedBy.isEmpty
    }
}
