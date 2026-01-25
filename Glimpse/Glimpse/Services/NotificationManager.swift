import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    func notifyTaskCompleted(_ task: Task, session: Session?) {
        let content = UNMutableNotificationContent()
        content.title = "Task Completed"
        content.body = task.subject
        if let sessionName = session?.displayName {
            content.subtitle = sessionName
        }
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "task-\(task.id)-completed",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    func notifySessionCompleted(_ session: Session) {
        let content = UNMutableNotificationContent()
        content.title = "Session Completed"
        content.body = "All tasks in \(session.displayName) are done!"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "session-\(session.id)-completed",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    func notifyTaskBlocked(_ task: Task) {
        let content = UNMutableNotificationContent()
        content.title = "Task Blocked"
        content.body = "\(task.subject) is waiting on dependencies"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "task-\(task.id)-blocked",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
