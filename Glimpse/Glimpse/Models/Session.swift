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

    var isOrphan: Bool {
        // Orphan if: older than 30 days, OR no matching project, OR all completed
        daysSinceModified > 30 || !hasMatchingProject || isAllCompleted
    }

    var orphanReason: String? {
        if !hasMatchingProject {
            return "No matching project"
        } else if daysSinceModified > 30 {
            return "Older than 30 days"
        } else if isAllCompleted {
            return "All tasks completed"
        }
        return nil
    }
}
