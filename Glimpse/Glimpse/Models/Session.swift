import Foundation

struct Session: Identifiable, Equatable {
    let id: String
    var name: String?
    var slug: String?
    var project: String?
    var gitBranch: String?
    var taskCount: Int
    var completed: Int
    var inProgress: Int
    var pending: Int
    var modifiedAt: Date
    var hasMatchingProject: Bool = true

    var displayName: String {
        name ?? slug ?? String(id.prefix(8))
    }

    var hasActiveTasks: Bool {
        inProgress > 0
    }

    var daysSinceModified: Int {
        Calendar.current.dateComponents([.day], from: modifiedAt, to: Date()).day ?? 0
    }

    var isAllCompleted: Bool {
        taskCount > 0 && completed == taskCount
    }

    /// Default orphan age threshold in days
    static let defaultOrphanAgeDays = 30

    var isOrphan: Bool {
        isOrphan(ageDays: Self.defaultOrphanAgeDays)
    }

    /// Check if session is orphaned with configurable age threshold
    func isOrphan(ageDays: Int) -> Bool {
        daysSinceModified > ageDays || !hasMatchingProject || isAllCompleted
    }

    var orphanReason: String? {
        orphanReason(ageDays: Self.defaultOrphanAgeDays)
    }

    /// Get orphan reason with configurable age threshold
    func orphanReason(ageDays: Int) -> String? {
        if !hasMatchingProject {
            return "No matching project"
        } else if daysSinceModified > ageDays {
            return "Older than \(ageDays) days"
        } else if isAllCompleted {
            return "All tasks completed"
        }
        return nil
    }
}
