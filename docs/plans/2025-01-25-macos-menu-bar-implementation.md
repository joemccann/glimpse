# macOS Menu Bar App Implementation Plan

> **Note:** This plan was written when the app was named "ClaudeTaskViewer". The project has since been renamed to "Glimpse". File paths like `ClaudeTaskViewer/...` now correspond to `Glimpse/...`.

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a native macOS menu bar app that displays Claude Code tasks in a Kanban-style popover with real-time file watching and notification support.

**Architecture:** SwiftUI + AppKit hybrid using NSPopover for the menu bar UI, FSEvents for file watching, and UserNotifications for alerts. Data is read directly from `~/.claude/tasks/` JSON files.

**Tech Stack:** Swift 5.9+, SwiftUI, AppKit, FSEvents, UserNotifications, macOS 13+

---

## Phase 1: Project Setup & Core Infrastructure

### Task 1: Create Xcode Project Structure

**Files:**
- Create: `ClaudeTaskViewer/ClaudeTaskViewer.xcodeproj`
- Create: `ClaudeTaskViewer/ClaudeTaskViewer/App/ClaudeTaskViewerApp.swift`
- Create: `ClaudeTaskViewer/ClaudeTaskViewer/App/AppDelegate.swift`

**Step 1: Move existing web app to subfolder**

```bash
mkdir -p web-app
git mv server.js public package.json package-lock.json node_modules README.md LICENSE screenshot-*.png web-app/
```

**Step 2: Create Xcode project using command line**

```bash
mkdir -p ClaudeTaskViewer/ClaudeTaskViewer/App
mkdir -p ClaudeTaskViewer/ClaudeTaskViewer/Views
mkdir -p ClaudeTaskViewer/ClaudeTaskViewer/Models
mkdir -p ClaudeTaskViewer/ClaudeTaskViewer/Services
mkdir -p ClaudeTaskViewer/ClaudeTaskViewer/Utilities
mkdir -p ClaudeTaskViewer/ClaudeTaskViewer/Resources
mkdir -p ClaudeTaskViewer/ClaudeTaskViewerTests
```

**Step 3: Create App entry point**

Create `ClaudeTaskViewer/ClaudeTaskViewer/App/ClaudeTaskViewerApp.swift`:

```swift
import SwiftUI

@main
struct ClaudeTaskViewerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            Text("Preferences coming soon")
                .frame(width: 300, height: 200)
        }
    }
}
```

**Step 4: Create AppDelegate skeleton**

Create `ClaudeTaskViewer/ClaudeTaskViewer/App/AppDelegate.swift`:

```swift
import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "checkmark.circle", accessibilityDescription: "Claude Tasks")
            button.action = #selector(togglePopover)
            button.target = self
        }

        popover = NSPopover()
        popover?.contentSize = NSSize(width: 400, height: 500)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: Text("Hello from Claude Task Viewer"))
    }

    @objc func togglePopover() {
        guard let button = statusItem?.button, let popover = popover else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
```

**Step 5: Create Package.swift for SPM-based build**

Create `ClaudeTaskViewer/Package.swift`:

```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ClaudeTaskViewer",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "ClaudeTaskViewer",
            path: "ClaudeTaskViewer"
        )
    ]
)
```

**Step 6: Build and verify**

```bash
cd ClaudeTaskViewer && swift build
```

Expected: Build succeeds

**Step 7: Commit**

```bash
git add -A
git commit -m "feat: scaffold macOS menu bar app with basic popover"
```

---

### Task 2: Create Data Models

**Files:**
- Create: `ClaudeTaskViewer/ClaudeTaskViewer/Models/Task.swift`
- Create: `ClaudeTaskViewer/ClaudeTaskViewer/Models/Session.swift`
- Create: `ClaudeTaskViewer/ClaudeTaskViewer/Models/Preferences.swift`
- Create: `ClaudeTaskViewer/ClaudeTaskViewerTests/TaskTests.swift`

**Step 1: Write failing test for Task model**

Create `ClaudeTaskViewer/ClaudeTaskViewerTests/TaskTests.swift`:

```swift
import XCTest
@testable import ClaudeTaskViewer

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
```

**Step 2: Run test to verify it fails**

```bash
cd ClaudeTaskViewer && swift test --filter TaskTests
```

Expected: FAIL - Task type not found

**Step 3: Create Task model**

Create `ClaudeTaskViewer/ClaudeTaskViewer/Models/Task.swift`:

```swift
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
```

**Step 4: Run test to verify it passes**

```bash
cd ClaudeTaskViewer && swift test --filter TaskTests
```

Expected: PASS

**Step 5: Create Session model**

Create `ClaudeTaskViewer/ClaudeTaskViewer/Models/Session.swift`:

```swift
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

    var displayName: String {
        name ?? slug ?? String(id.prefix(8))
    }

    var hasActiveTasks: Bool {
        inProgress > 0
    }
}
```

**Step 6: Create Preferences model**

Create `ClaudeTaskViewer/ClaudeTaskViewer/Models/Preferences.swift`:

```swift
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
```

**Step 7: Commit**

```bash
git add -A
git commit -m "feat: add Task, Session, and Preferences data models"
```

---

### Task 3: Implement TaskManager Service

**Files:**
- Create: `ClaudeTaskViewer/ClaudeTaskViewer/Services/TaskManager.swift`
- Create: `ClaudeTaskViewer/ClaudeTaskViewerTests/TaskManagerTests.swift`

**Step 1: Write failing test**

Create `ClaudeTaskViewer/ClaudeTaskViewerTests/TaskManagerTests.swift`:

```swift
import XCTest
@testable import ClaudeTaskViewer

final class TaskManagerTests: XCTestCase {
    var taskManager: TaskManager!
    var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        taskManager = TaskManager(tasksDirectory: tempDir.path)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    func testLoadTasksFromSession() throws {
        // Create session directory
        let sessionDir = tempDir.appendingPathComponent("session-123")
        try FileManager.default.createDirectory(at: sessionDir, withIntermediateDirectories: true)

        // Create task file
        let taskJSON = """
        {"id": "1", "subject": "Test task", "status": "pending"}
        """
        try taskJSON.write(to: sessionDir.appendingPathComponent("1.json"), atomically: true, encoding: .utf8)

        let tasks = taskManager.loadTasks(sessionId: "session-123")

        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.subject, "Test task")
    }
}
```

**Step 2: Run test to verify it fails**

```bash
cd ClaudeTaskViewer && swift test --filter TaskManagerTests
```

Expected: FAIL - TaskManager not found

**Step 3: Implement TaskManager**

Create `ClaudeTaskViewer/ClaudeTaskViewer/Services/TaskManager.swift`:

```swift
import Foundation
import Combine

class TaskManager: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var activeTasks: [Task] = []

    private let tasksDirectory: String
    private let fileManager = FileManager.default

    init(tasksDirectory: String? = nil) {
        self.tasksDirectory = tasksDirectory ??
            fileManager.homeDirectoryForCurrentUser
                .appendingPathComponent(".claude/tasks").path
    }

    func loadTasks(sessionId: String) -> [Task] {
        let sessionPath = (tasksDirectory as NSString).appendingPathComponent(sessionId)

        guard fileManager.fileExists(atPath: sessionPath) else {
            return []
        }

        do {
            let files = try fileManager.contentsOfDirectory(atPath: sessionPath)
                .filter { $0.hasSuffix(".json") }

            var tasks: [Task] = []
            for file in files {
                let filePath = (sessionPath as NSString).appendingPathComponent(file)
                let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
                var task = try JSONDecoder().decode(Task.self, from: data)
                task.sessionId = sessionId
                tasks.append(task)
            }

            return tasks.sorted {
                (Int($0.id) ?? 0) < (Int($1.id) ?? 0)
            }
        } catch {
            print("Error loading tasks: \(error)")
            return []
        }
    }

    func loadAllTasks() -> [Task] {
        guard fileManager.fileExists(atPath: tasksDirectory) else {
            return []
        }

        do {
            let sessionDirs = try fileManager.contentsOfDirectory(atPath: tasksDirectory)
            var allTasks: [Task] = []

            for sessionId in sessionDirs {
                let sessionTasks = loadTasks(sessionId: sessionId)
                allTasks.append(contentsOf: sessionTasks)
            }

            return allTasks
        } catch {
            print("Error loading all tasks: \(error)")
            return []
        }
    }

    func addNote(sessionId: String, taskId: String, note: String) throws {
        let filePath = (tasksDirectory as NSString)
            .appendingPathComponent(sessionId)
            .appendingPathComponent("\(taskId).json") as String

        let url = URL(fileURLWithPath: filePath)
        let data = try Data(contentsOf: url)
        var task = try JSONDecoder().decode(Task.self, from: data)

        let noteBlock = "\n\n---\n\n#### [Note added by user]\n\n\(note.trimmingCharacters(in: .whitespacesAndNewlines))"
        task.description = (task.description ?? "") + noteBlock

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let updatedData = try encoder.encode(task)
        try updatedData.write(to: url)
    }
}
```

**Step 4: Run test to verify it passes**

```bash
cd ClaudeTaskViewer && swift test --filter TaskManagerTests
```

Expected: PASS

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: add TaskManager service for loading tasks from filesystem"
```

---

### Task 4: Implement SessionManager Service

**Files:**
- Create: `ClaudeTaskViewer/ClaudeTaskViewer/Services/SessionManager.swift`
- Create: `ClaudeTaskViewer/ClaudeTaskViewerTests/SessionManagerTests.swift`

**Step 1: Write failing test**

Create `ClaudeTaskViewer/ClaudeTaskViewerTests/SessionManagerTests.swift`:

```swift
import XCTest
@testable import ClaudeTaskViewer

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
```

**Step 2: Run test to verify it fails**

```bash
cd ClaudeTaskViewer && swift test --filter SessionManagerTests
```

Expected: FAIL - SessionManager not found

**Step 3: Implement SessionManager**

Create `ClaudeTaskViewer/ClaudeTaskViewer/Services/SessionManager.swift`:

```swift
import Foundation
import Combine

class SessionManager: ObservableObject {
    @Published var sessions: [Session] = []

    private let claudeDirectory: String
    private let fileManager = FileManager.default

    var tasksDirectory: String {
        (claudeDirectory as NSString).appendingPathComponent("tasks")
    }

    var projectsDirectory: String {
        (claudeDirectory as NSString).appendingPathComponent("projects")
    }

    init(claudeDirectory: String? = nil) {
        self.claudeDirectory = claudeDirectory ??
            fileManager.homeDirectoryForCurrentUser
                .appendingPathComponent(".claude").path
    }

    func loadSessions() {
        guard fileManager.fileExists(atPath: tasksDirectory) else {
            sessions = []
            return
        }

        do {
            let metadata = loadSessionMetadata()
            let entries = try fileManager.contentsOfDirectory(atPath: tasksDirectory)
            var loadedSessions: [Session] = []

            for entry in entries {
                let sessionPath = (tasksDirectory as NSString).appendingPathComponent(entry)
                var isDirectory: ObjCBool = false

                guard fileManager.fileExists(atPath: sessionPath, isDirectory: &isDirectory),
                      isDirectory.boolValue else { continue }

                let taskFiles = try fileManager.contentsOfDirectory(atPath: sessionPath)
                    .filter { $0.hasSuffix(".json") }

                var completed = 0, inProgress = 0, pending = 0

                for file in taskFiles {
                    let filePath = (sessionPath as NSString).appendingPathComponent(file)
                    if let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
                       let task = try? JSONDecoder().decode(Task.self, from: data) {
                        switch task.status {
                        case .completed: completed += 1
                        case .inProgress: inProgress += 1
                        case .pending: pending += 1
                        }
                    }
                }

                let attrs = try fileManager.attributesOfItem(atPath: sessionPath)
                let modifiedAt = attrs[.modificationDate] as? Date ?? Date()

                let meta = metadata[entry]

                loadedSessions.append(Session(
                    id: entry,
                    name: meta?.customTitle,
                    slug: meta?.slug,
                    project: meta?.project,
                    gitBranch: meta?.gitBranch,
                    taskCount: taskFiles.count,
                    completed: completed,
                    inProgress: inProgress,
                    pending: pending,
                    modifiedAt: modifiedAt
                ))
            }

            sessions = loadedSessions.sorted { $0.modifiedAt > $1.modifiedAt }
        } catch {
            print("Error loading sessions: \(error)")
            sessions = []
        }
    }

    private func loadSessionMetadata() -> [String: SessionMetadata] {
        var metadata: [String: SessionMetadata] = [:]

        guard fileManager.fileExists(atPath: projectsDirectory) else {
            return metadata
        }

        do {
            let projectDirs = try fileManager.contentsOfDirectory(atPath: projectsDirectory)

            for projectDir in projectDirs {
                let projectPath = (projectsDirectory as NSString).appendingPathComponent(projectDir)
                var isDirectory: ObjCBool = false

                guard fileManager.fileExists(atPath: projectPath, isDirectory: &isDirectory),
                      isDirectory.boolValue else { continue }

                let files = try fileManager.contentsOfDirectory(atPath: projectPath)
                    .filter { $0.hasSuffix(".jsonl") }

                let projectName = "/" + projectDir.replacingOccurrences(of: "-", with: "/")
                    .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

                for file in files {
                    let sessionId = file.replacingOccurrences(of: ".jsonl", with: "")
                    let jsonlPath = (projectPath as NSString).appendingPathComponent(file)
                    let info = readSessionInfoFromJsonl(path: jsonlPath)

                    metadata[sessionId] = SessionMetadata(
                        customTitle: info.customTitle,
                        slug: info.slug,
                        project: projectName,
                        gitBranch: nil
                    )
                }

                // Check sessions-index.json for additional metadata
                let indexPath = (projectPath as NSString).appendingPathComponent("sessions-index.json")
                if fileManager.fileExists(atPath: indexPath),
                   let data = try? Data(contentsOf: URL(fileURLWithPath: indexPath)),
                   let index = try? JSONDecoder().decode(SessionsIndex.self, from: data) {
                    for entry in index.entries {
                        if var existing = metadata[entry.sessionId] {
                            existing.gitBranch = entry.gitBranch
                            if let name = entry.customName ?? entry.name {
                                existing.customTitle = name
                            }
                            metadata[entry.sessionId] = existing
                        }
                    }
                }
            }
        } catch {
            print("Error loading session metadata: \(error)")
        }

        return metadata
    }

    private func readSessionInfoFromJsonl(path: String) -> (customTitle: String?, slug: String?) {
        var customTitle: String?
        var slug: String?

        guard let handle = FileHandle(forReadingAtPath: path) else {
            return (nil, nil)
        }
        defer { try? handle.close() }

        let data = handle.readData(ofLength: 65536)
        guard let content = String(data: data, encoding: .utf8) else {
            return (nil, nil)
        }

        for line in content.split(separator: "\n") {
            guard let lineData = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any] else {
                continue
            }

            if let type = json["type"] as? String, type == "custom-title",
               let title = json["customTitle"] as? String {
                customTitle = title
            }

            if slug == nil, let s = json["slug"] as? String {
                slug = s
            }

            if customTitle != nil && slug != nil { break }
        }

        return (customTitle, slug)
    }
}

private struct SessionMetadata {
    var customTitle: String?
    var slug: String?
    var project: String?
    var gitBranch: String?
}

private struct SessionsIndex: Codable {
    let entries: [SessionIndexEntry]
}

private struct SessionIndexEntry: Codable {
    let sessionId: String
    var customName: String?
    var name: String?
    var gitBranch: String?
}
```

**Step 4: Run test to verify it passes**

```bash
cd ClaudeTaskViewer && swift test --filter SessionManagerTests
```

Expected: PASS

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: add SessionManager service for loading session metadata"
```

---

### Task 5: Implement FileWatcher Service

**Files:**
- Create: `ClaudeTaskViewer/ClaudeTaskViewer/Services/FileWatcher.swift`

**Step 1: Create FileWatcher**

Create `ClaudeTaskViewer/ClaudeTaskViewer/Services/FileWatcher.swift`:

```swift
import Foundation
import Combine

class FileWatcher: ObservableObject {
    @Published var lastUpdate: Date = Date()

    private var stream: FSEventStreamRef?
    private let path: String
    private var callback: (() -> Void)?

    init(path: String) {
        self.path = path
    }

    func start(onChange: @escaping () -> Void) {
        callback = onChange

        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let paths = [path] as CFArray

        stream = FSEventStreamCreate(
            nil,
            { (_, info, numEvents, eventPaths, _, _) in
                guard let info = info else { return }
                let watcher = Unmanaged<FileWatcher>.fromOpaque(info).takeUnretainedValue()
                DispatchQueue.main.async {
                    watcher.lastUpdate = Date()
                    watcher.callback?()
                }
            },
            &context,
            paths,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            1.0,
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes)
        )

        if let stream = stream {
            FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
            FSEventStreamStart(stream)
        }
    }

    func stop() {
        if let stream = stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            self.stream = nil
        }
    }

    deinit {
        stop()
    }
}
```

**Step 2: Verify build**

```bash
cd ClaudeTaskViewer && swift build
```

Expected: Build succeeds

**Step 3: Commit**

```bash
git add -A
git commit -m "feat: add FileWatcher service using FSEvents"
```

---

## Phase 2: UI Views

### Task 6: Create Theme Utilities

**Files:**
- Create: `ClaudeTaskViewer/ClaudeTaskViewer/Utilities/Theme.swift`

**Step 1: Create Theme**

Create `ClaudeTaskViewer/ClaudeTaskViewer/Utilities/Theme.swift`:

```swift
import SwiftUI

struct Theme {
    // Dark theme colors
    static let darkBgDeep = Color(hex: "08090a")
    static let darkBgSurface = Color(hex: "0d0e10")
    static let darkBgElevated = Color(hex: "131416")
    static let darkBgHover = Color(hex: "1a1b1e")
    static let darkBorder = Color(hex: "1e2023")
    static let darkTextPrimary = Color(hex: "e8e8e8")
    static let darkTextSecondary = Color(hex: "8b8d91")
    static let darkTextTertiary = Color(hex: "5a5c60")
    static let darkTextMuted = Color(hex: "3d3f42")

    // Light theme colors
    static let lightBgDeep = Color(hex: "fafafa")
    static let lightBgSurface = Color(hex: "ffffff")
    static let lightBgElevated = Color(hex: "f5f5f5")
    static let lightBgHover = Color(hex: "efefef")
    static let lightBorder = Color(hex: "e5e5e5")
    static let lightTextPrimary = Color(hex: "171717")
    static let lightTextSecondary = Color(hex: "525252")
    static let lightTextTertiary = Color(hex: "737373")
    static let lightTextMuted = Color(hex: "a3a3a3")

    // Accent colors
    static let accent = Color(hex: "E86F33")
    static let success = Color(hex: "3ecf8e")
    static let warning = Color(hex: "f0b429")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}
```

**Step 2: Commit**

```bash
git add -A
git commit -m "feat: add Theme utilities with Terminal Luxe colors"
```

---

### Task 7: Create TaskCardView

**Files:**
- Create: `ClaudeTaskViewer/ClaudeTaskViewer/Views/TaskCardView.swift`

**Step 1: Create TaskCardView**

Create `ClaudeTaskViewer/ClaudeTaskViewer/Views/TaskCardView.swift`:

```swift
import SwiftUI

struct TaskCardView: View {
    let task: Task
    let onTap: () -> Void

    @Environment(\.colorScheme) var colorScheme

    private var bgColor: Color {
        colorScheme == .dark ? Theme.darkBgElevated : Theme.lightBgElevated
    }

    private var textPrimary: Color {
        colorScheme == .dark ? Theme.darkTextPrimary : Theme.lightTextPrimary
    }

    private var textSecondary: Color {
        colorScheme == .dark ? Theme.darkTextSecondary : Theme.lightTextSecondary
    }

    private var borderColor: Color {
        colorScheme == .dark ? Theme.darkBorder : Theme.lightBorder
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("#\(task.id)")
                        .font(.caption)
                        .foregroundColor(textSecondary)

                    Spacer()

                    if task.isBlocked {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Theme.warning)
                            .font(.caption)
                    }
                }

                Text(task.subject)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let activeForm = task.activeForm, task.status == .inProgress {
                    Text(activeForm)
                        .font(.caption)
                        .foregroundColor(Theme.accent)
                        .lineLimit(1)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(bgColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .modifier(PulseModifier(isActive: task.status == .inProgress))
    }
}

struct PulseModifier: ViewModifier {
    let isActive: Bool
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .opacity(isActive && isPulsing ? 0.8 : 1.0)
            .scaleEffect(isActive && isPulsing ? 0.98 : 1.0)
            .animation(
                isActive ? Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true) : .default,
                value: isPulsing
            )
            .onAppear {
                if isActive { isPulsing = true }
            }
            .onChange(of: isActive) { _, newValue in
                isPulsing = newValue
            }
    }
}
```

**Step 2: Commit**

```bash
git add -A
git commit -m "feat: add TaskCardView with pulse animation"
```

---

### Task 8: Create KanbanView

**Files:**
- Create: `ClaudeTaskViewer/ClaudeTaskViewer/Views/KanbanView.swift`

**Step 1: Create KanbanView**

Create `ClaudeTaskViewer/ClaudeTaskViewer/Views/KanbanView.swift`:

```swift
import SwiftUI

struct KanbanView: View {
    let tasks: [Task]
    let onTaskTap: (Task) -> Void

    @Environment(\.colorScheme) var colorScheme

    private var pendingTasks: [Task] {
        tasks.filter { $0.status == .pending }
    }

    private var inProgressTasks: [Task] {
        tasks.filter { $0.status == .inProgress }
    }

    private var completedTasks: [Task] {
        tasks.filter { $0.status == .completed }
    }

    private var bgDeep: Color {
        colorScheme == .dark ? Theme.darkBgDeep : Theme.lightBgDeep
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            KanbanColumn(
                title: "Pending",
                count: pendingTasks.count,
                color: Theme.darkTextSecondary,
                tasks: pendingTasks,
                onTaskTap: onTaskTap
            )

            KanbanColumn(
                title: "In Progress",
                count: inProgressTasks.count,
                color: Theme.accent,
                tasks: inProgressTasks,
                onTaskTap: onTaskTap
            )

            KanbanColumn(
                title: "Completed",
                count: completedTasks.count,
                color: Theme.success,
                tasks: completedTasks,
                onTaskTap: onTaskTap
            )
        }
        .padding()
        .background(bgDeep)
    }
}

struct KanbanColumn: View {
    let title: String
    let count: Int
    let color: Color
    let tasks: [Task]
    let onTaskTap: (Task) -> Void

    @Environment(\.colorScheme) var colorScheme

    private var textPrimary: Color {
        colorScheme == .dark ? Theme.darkTextPrimary : Theme.lightTextPrimary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(textPrimary)

                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(color)
                    .cornerRadius(10)
            }

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(tasks) { task in
                        TaskCardView(task: task) {
                            onTaskTap(task)
                        }
                    }
                }
            }
        }
        .frame(minWidth: 110, maxWidth: .infinity)
    }
}
```

**Step 2: Commit**

```bash
git add -A
git commit -m "feat: add KanbanView with three-column layout"
```

---

### Task 9: Create TaskDetailView

**Files:**
- Create: `ClaudeTaskViewer/ClaudeTaskViewer/Views/TaskDetailView.swift`

**Step 1: Create TaskDetailView**

Create `ClaudeTaskViewer/ClaudeTaskViewer/Views/TaskDetailView.swift`:

```swift
import SwiftUI

struct TaskDetailView: View {
    let task: Task
    let onAddNote: (String) -> Void
    let onDismiss: () -> Void

    @State private var noteText = ""
    @Environment(\.colorScheme) var colorScheme

    private var bgSurface: Color {
        colorScheme == .dark ? Theme.darkBgSurface : Theme.lightBgSurface
    }

    private var textPrimary: Color {
        colorScheme == .dark ? Theme.darkTextPrimary : Theme.lightTextPrimary
    }

    private var textSecondary: Color {
        colorScheme == .dark ? Theme.darkTextSecondary : Theme.lightTextSecondary
    }

    private var borderColor: Color {
        colorScheme == .dark ? Theme.darkBorder : Theme.lightBorder
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("#\(task.id)")
                        .font(.caption)
                        .foregroundColor(textSecondary)
                    Text(task.subject)
                        .font(.headline)
                        .foregroundColor(textPrimary)
                }

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(textSecondary)
                }
                .buttonStyle(.plain)
            }

            Divider()

            // Status
            HStack {
                Text("Status:")
                    .foregroundColor(textSecondary)
                StatusBadge(status: task.status)
            }

            // Description
            if let description = task.description, !description.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Description")
                        .font(.subheadline)
                        .foregroundColor(textSecondary)

                    ScrollView {
                        Text(description)
                            .font(.body)
                            .foregroundColor(textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 150)
                }
            }

            // Dependencies
            if let blocks = task.blocks, !blocks.isEmpty {
                HStack {
                    Text("Blocks:")
                        .foregroundColor(textSecondary)
                    Text(blocks.joined(separator: ", "))
                        .foregroundColor(Theme.warning)
                }
            }

            if let blockedBy = task.blockedBy, !blockedBy.isEmpty {
                HStack {
                    Text("Blocked by:")
                        .foregroundColor(textSecondary)
                    Text(blockedBy.joined(separator: ", "))
                        .foregroundColor(Theme.warning)
                }
            }

            Divider()

            // Add note
            VStack(alignment: .leading, spacing: 8) {
                Text("Add Note")
                    .font(.subheadline)
                    .foregroundColor(textSecondary)

                TextEditor(text: $noteText)
                    .frame(height: 60)
                    .padding(4)
                    .background(bgSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(borderColor, lineWidth: 1)
                    )

                Button("Add Note") {
                    if !noteText.isEmpty {
                        onAddNote(noteText)
                        noteText = ""
                    }
                }
                .disabled(noteText.isEmpty)
            }

            Spacer()
        }
        .padding()
        .frame(width: 350, height: 450)
        .background(bgSurface)
    }
}

struct StatusBadge: View {
    let status: TaskStatus

    var color: Color {
        switch status {
        case .pending: return Theme.darkTextSecondary
        case .inProgress: return Theme.accent
        case .completed: return Theme.success
        }
    }

    var label: String {
        switch status {
        case .pending: return "Pending"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        }
    }

    var body: some View {
        Text(label)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(4)
    }
}
```

**Step 2: Commit**

```bash
git add -A
git commit -m "feat: add TaskDetailView with note input"
```

---

### Task 10: Create MenuBarView (Main Popover Content)

**Files:**
- Create: `ClaudeTaskViewer/ClaudeTaskViewer/Views/MenuBarView.swift`

**Step 1: Create MenuBarView**

Create `ClaudeTaskViewer/ClaudeTaskViewer/Views/MenuBarView.swift`:

```swift
import SwiftUI

struct MenuBarView: View {
    @StateObject private var sessionManager = SessionManager()
    @StateObject private var taskManager = TaskManager()
    @StateObject private var fileWatcher: FileWatcher

    @State private var selectedSessionId: String?
    @State private var selectedTask: Task?
    @State private var searchText = ""

    @Environment(\.colorScheme) var colorScheme

    init() {
        let claudeDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude").path
        _fileWatcher = StateObject(wrappedValue: FileWatcher(path: claudeDir + "/tasks"))
    }

    private var bgDeep: Color {
        colorScheme == .dark ? Theme.darkBgDeep : Theme.lightBgDeep
    }

    private var textPrimary: Color {
        colorScheme == .dark ? Theme.darkTextPrimary : Theme.lightTextPrimary
    }

    private var textSecondary: Color {
        colorScheme == .dark ? Theme.darkTextSecondary : Theme.lightTextSecondary
    }

    private var currentTasks: [Task] {
        var tasks: [Task]
        if let sessionId = selectedSessionId {
            tasks = taskManager.loadTasks(sessionId: sessionId)
        } else {
            tasks = taskManager.loadAllTasks()
        }

        if searchText.isEmpty {
            return tasks
        }

        return tasks.filter {
            $0.subject.localizedCaseInsensitiveContains(searchText) ||
            ($0.description?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.accent)
                    Text("Claude Tasks")
                        .font(.headline)
                        .foregroundColor(textPrimary)
                    Spacer()

                    // Active indicator
                    if sessionManager.sessions.contains(where: { $0.hasActiveTasks }) {
                        Circle()
                            .fill(Theme.accent)
                            .frame(width: 8, height: 8)
                    }
                }

                // Session picker
                Picker("Session", selection: $selectedSessionId) {
                    Text("All Sessions").tag(nil as String?)
                    ForEach(sessionManager.sessions) { session in
                        Text(session.displayName).tag(session.id as String?)
                    }
                }
                .pickerStyle(.menu)

                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(textSecondary)
                    TextField("Search tasks...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(6)
                .background(colorScheme == .dark ? Theme.darkBgElevated : Theme.lightBgElevated)
                .cornerRadius(6)
            }
            .padding()
            .background(colorScheme == .dark ? Theme.darkBgSurface : Theme.lightBgSurface)

            // Kanban board
            KanbanView(tasks: currentTasks) { task in
                selectedTask = task
            }
        }
        .frame(width: 400, height: 500)
        .background(bgDeep)
        .onAppear {
            sessionManager.loadSessions()
            fileWatcher.start {
                sessionManager.loadSessions()
            }
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailView(
                task: task,
                onAddNote: { note in
                    if let sessionId = task.sessionId ?? selectedSessionId {
                        try? taskManager.addNote(sessionId: sessionId, taskId: task.id, note: note)
                        sessionManager.loadSessions()
                    }
                },
                onDismiss: { selectedTask = nil }
            )
        }
    }
}
```

**Step 2: Commit**

```bash
git add -A
git commit -m "feat: add MenuBarView with session picker and search"
```

---

### Task 11: Wire Up AppDelegate with MenuBarView

**Files:**
- Modify: `ClaudeTaskViewer/ClaudeTaskViewer/App/AppDelegate.swift`

**Step 1: Update AppDelegate**

Update `ClaudeTaskViewer/ClaudeTaskViewer/App/AppDelegate.swift`:

```swift
import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "checkmark.circle", accessibilityDescription: "Claude Tasks")
            button.action = #selector(togglePopover)
            button.target = self

            // Right-click menu
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ","))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        popover = NSPopover()
        popover?.contentSize = NSSize(width: 400, height: 500)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: MenuBarView())
    }

    @objc func togglePopover(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            guard let button = statusItem?.button, let popover = popover else { return }

            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }

    private func showContextMenu() {
        guard let button = statusItem?.button else { return }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        statusItem?.menu = menu
        button.performClick(nil)
        statusItem?.menu = nil
    }

    @objc func openPreferences() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }
}
```

**Step 2: Build and test**

```bash
cd ClaudeTaskViewer && swift build
```

Expected: Build succeeds

**Step 3: Commit**

```bash
git add -A
git commit -m "feat: wire MenuBarView to AppDelegate popover"
```

---

## Phase 3: Notifications & Preferences

### Task 12: Implement NotificationManager

**Files:**
- Create: `ClaudeTaskViewer/ClaudeTaskViewer/Services/NotificationManager.swift`

**Step 1: Create NotificationManager**

Create `ClaudeTaskViewer/ClaudeTaskViewer/Services/NotificationManager.swift`:

```swift
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
```

**Step 2: Commit**

```bash
git add -A
git commit -m "feat: add NotificationManager for macOS notifications"
```

---

### Task 13: Create PreferencesView

**Files:**
- Create: `ClaudeTaskViewer/ClaudeTaskViewer/Views/PreferencesView.swift`

**Step 1: Create PreferencesView**

Create `ClaudeTaskViewer/ClaudeTaskViewer/Views/PreferencesView.swift`:

```swift
import SwiftUI

struct PreferencesView: View {
    @AppStorage("claudeDirectory") private var claudeDirectory = FileManager.default
        .homeDirectoryForCurrentUser.appendingPathComponent(".claude").path
    @AppStorage("notifyOnTaskComplete") private var notifyOnTaskComplete = true
    @AppStorage("notifyOnSessionComplete") private var notifyOnSessionComplete = true
    @AppStorage("notifyOnBlocked") private var notifyOnBlocked = false
    @AppStorage("theme") private var theme = "system"

    var body: some View {
        Form {
            Section("Claude Directory") {
                HStack {
                    TextField("Path", text: $claudeDirectory)
                        .textFieldStyle(.roundedBorder)

                    Button("Browse...") {
                        selectDirectory()
                    }
                }
            }

            Section("Notifications") {
                Toggle("Notify when task completes", isOn: $notifyOnTaskComplete)
                Toggle("Notify when session completes", isOn: $notifyOnSessionComplete)
                Toggle("Notify when task is blocked", isOn: $notifyOnBlocked)
            }

            Section("Appearance") {
                Picker("Theme", selection: $theme) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.segmented)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 300)
    }

    private func selectDirectory() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false

        if panel.runModal() == .OK, let url = panel.url {
            claudeDirectory = url.path
        }
    }
}
```

**Step 2: Update App entry point**

Update `ClaudeTaskViewer/ClaudeTaskViewer/App/ClaudeTaskViewerApp.swift`:

```swift
import SwiftUI

@main
struct ClaudeTaskViewerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            PreferencesView()
        }
    }
}
```

**Step 3: Commit**

```bash
git add -A
git commit -m "feat: add PreferencesView with notifications and theme settings"
```

---

## Phase 4: Finalization

### Task 14: Create App Icon and Assets

**Files:**
- Create: `ClaudeTaskViewer/ClaudeTaskViewer/Resources/Assets.xcassets/`

**Step 1: Create Assets catalog structure**

```bash
mkdir -p ClaudeTaskViewer/ClaudeTaskViewer/Resources/Assets.xcassets/AppIcon.appiconset
mkdir -p ClaudeTaskViewer/ClaudeTaskViewer/Resources/Assets.xcassets/MenuBarIcon.imageset
```

**Step 2: Create Contents.json for AppIcon**

Create `ClaudeTaskViewer/ClaudeTaskViewer/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json`:

```json
{
  "images" : [
    { "idiom" : "mac", "scale" : "1x", "size" : "16x16" },
    { "idiom" : "mac", "scale" : "2x", "size" : "16x16" },
    { "idiom" : "mac", "scale" : "1x", "size" : "32x32" },
    { "idiom" : "mac", "scale" : "2x", "size" : "32x32" },
    { "idiom" : "mac", "scale" : "1x", "size" : "128x128" },
    { "idiom" : "mac", "scale" : "2x", "size" : "128x128" },
    { "idiom" : "mac", "scale" : "1x", "size" : "256x256" },
    { "idiom" : "mac", "scale" : "2x", "size" : "256x256" },
    { "idiom" : "mac", "scale" : "1x", "size" : "512x512" },
    { "idiom" : "mac", "scale" : "2x", "size" : "512x512" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
```

**Step 3: Commit**

```bash
git add -A
git commit -m "feat: add Assets catalog structure for app icons"
```

---

### Task 15: Create Info.plist for LSUIElement (Hide Dock Icon)

**Files:**
- Create: `ClaudeTaskViewer/ClaudeTaskViewer/Resources/Info.plist`

**Step 1: Create Info.plist**

Create `ClaudeTaskViewer/ClaudeTaskViewer/Resources/Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Claude Task Viewer</string>
    <key>CFBundleIdentifier</key>
    <string>com.yourname.ClaudeTaskViewer</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2025</string>
</dict>
</plist>
```

**Step 2: Commit**

```bash
git add -A
git commit -m "feat: add Info.plist with LSUIElement to hide dock icon"
```

---

### Task 16: Final Integration Test

**Step 1: Build the app**

```bash
cd ClaudeTaskViewer && swift build -c release
```

Expected: Build succeeds

**Step 2: Run the app**

```bash
.build/release/ClaudeTaskViewer
```

Expected: Menu bar icon appears, clicking shows popover with tasks

**Step 3: Verify features**
- [ ] Menu bar icon visible
- [ ] Popover opens on click
- [ ] Sessions load from ~/.claude/tasks/
- [ ] Tasks display in kanban columns
- [ ] Task detail view opens on click
- [ ] Right-click shows context menu
- [ ] Preferences window opens

**Step 4: Final commit**

```bash
git add -A
git commit -m "chore: complete macOS menu bar app MVP"
```

---

## Summary

This plan builds the macOS menu bar app in 16 tasks across 4 phases:

1. **Phase 1 (Tasks 1-5):** Project setup, data models, services
2. **Phase 2 (Tasks 6-11):** UI views and integration
3. **Phase 3 (Tasks 12-13):** Notifications and preferences
4. **Phase 4 (Tasks 14-16):** Assets, configuration, final testing

Each task follows TDD where applicable and commits frequently.
