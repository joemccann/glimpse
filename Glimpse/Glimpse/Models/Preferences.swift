import Foundation

enum AppTheme: String, Codable, CaseIterable {
    case system
    case light
    case dark
}

struct Preferences: Codable {
    var claudeDirectory: String
    var notifyOnTaskComplete: Bool
    var notifyOnSessionComplete: Bool
    var notifyOnBlocked: Bool
    var theme: AppTheme

    static let `default` = Preferences(
        claudeDirectory: FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude").path,
        notifyOnTaskComplete: true,
        notifyOnSessionComplete: true,
        notifyOnBlocked: false,
        theme: .system
    )
}
