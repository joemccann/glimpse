# macOS Menu Bar App Design

> **Note:** This plan was written when the app was named "ClaudeTaskViewer". The project has since been renamed to "Glimpse". File paths like `ClaudeTaskViewer/...` now correspond to `Glimpse/...`.

## Overview

Refactor the Claude Task Viewer from a web application to a native macOS menu bar app using SwiftUI + AppKit. The app provides a Kanban-style view for monitoring and managing Claude Code tasks.

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Framework | SwiftUI + AppKit | Native performance, small memory footprint, best macOS integration |
| UI Structure | Popover panel | Natural menu bar UX, quick access, dismisses on click-outside |
| Data Access | Direct file system | No network overhead, FSEvents for efficient watching |
| Status Indicator | Animated | Pulse animation when tasks in progress, matches web aesthetic |
| Notifications | Configurable | Leverage native capability, user-tunable |
| Project Structure | Web app to subfolder | Clean separation, easy cleanup later |

## Project Structure

```
claude-task-viewer-macos-bar/
├── web-app/                    # Existing web app (relocated)
│   ├── server.js
│   ├── public/
│   ├── package.json
│   └── ...
│
├── ClaudeTaskViewer/           # Xcode project
│   ├── ClaudeTaskViewer.xcodeproj
│   ├── ClaudeTaskViewer/
│   │   ├── App/
│   │   │   ├── ClaudeTaskViewerApp.swift    # Entry point, menu bar setup
│   │   │   └── AppDelegate.swift            # NSApplicationDelegate for AppKit integration
│   │   ├── Views/
│   │   │   ├── MenuBarView.swift            # Popover content
│   │   │   ├── KanbanView.swift             # Three-column task board
│   │   │   ├── TaskCardView.swift           # Individual task card
│   │   │   ├── SessionListView.swift        # Sidebar session picker
│   │   │   ├── TaskDetailView.swift         # Detail panel with notes
│   │   │   └── PreferencesView.swift        # Settings window
│   │   ├── Models/
│   │   │   ├── Task.swift                   # Task data model
│   │   │   ├── Session.swift                # Session data model
│   │   │   └── Preferences.swift            # User preferences
│   │   ├── Services/
│   │   │   ├── FileWatcher.swift            # FSEvents wrapper
│   │   │   ├── TaskManager.swift            # Load/parse tasks
│   │   │   ├── SessionManager.swift         # Load/parse sessions
│   │   │   └── NotificationManager.swift    # macOS notifications
│   │   ├── Utilities/
│   │   │   └── Theme.swift                  # Colors matching web app
│   │   └── Resources/
│   │       └── Assets.xcassets              # App icons, menu bar icons
│   └── ClaudeTaskViewerTests/
├── README.md
└── LICENSE
```

## Data Models

### Task

```swift
struct Task: Identifiable, Codable {
    let id: String
    let subject: String
    var description: String?
    var activeForm: String?          // What Claude is currently doing
    var status: TaskStatus
    var blocks: [String]?            // Task IDs this blocks
    var blockedBy: [String]?         // Task IDs blocking this

    // Added for multi-session views
    var sessionId: String?
    var sessionName: String?
    var project: String?
}

enum TaskStatus: String, Codable {
    case pending
    case inProgress = "in_progress"
    case completed
}
```

### Session

```swift
struct Session: Identifiable {
    let id: String                   // UUID folder name
    var name: String?                // Custom title or slug
    var slug: String?
    var project: String?             // Project path
    var gitBranch: String?
    var taskCount: Int
    var completed: Int
    var inProgress: Int
    var pending: Int
    var modifiedAt: Date
}
```

### Preferences

```swift
struct Preferences: Codable {
    var claudeDirectory: String      // Default: ~/.claude
    var notifyOnTaskComplete: Bool
    var notifyOnSessionComplete: Bool
    var notifyOnBlocked: Bool
    var theme: Theme                 // .system, .light, .dark
}
```

## Services Layer

### FileWatcher

Monitors `~/.claude/tasks/` using FSEvents:

```swift
class FileWatcher: ObservableObject {
    @Published var lastUpdate: Date = Date()

    private var stream: FSEventStreamRef?
    private let tasksPath: String

    func start()  // Create FSEventStream, trigger updates on .json changes
    func stop()   // Cleanup stream
}
```

### TaskManager

```swift
class TaskManager: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var activeTasks: [Task] = []  // in_progress only

    func loadAllTasks() -> [Task]
    func loadTasks(sessionId: String) -> [Task]
    func addNote(sessionId: String, taskId: String, note: String) throws
}
```

### SessionManager

```swift
class SessionManager: ObservableObject {
    @Published var sessions: [Session] = []

    func loadSessions()
    // 1. Scan ~/.claude/tasks/ for session folders
    // 2. Read ~/.claude/projects/*/sessions-index.json for metadata
    // 3. Parse first 64KB of JSONL for customTitle/slug
}
```

### NotificationManager

```swift
class NotificationManager {
    static let shared = NotificationManager()

    func requestPermission()
    func notifyTaskCompleted(_ task: Task, session: Session?)
    func notifySessionCompleted(_ session: Session)
    func notifyTaskBlocked(_ task: Task, duration: TimeInterval)
}
```

## UI Views

### App Entry Point

```swift
@main
struct ClaudeTaskViewerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            PreferencesView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?

    // Create menu bar icon with animated state
    // Attach popover with MenuBarView
    // Start file watcher
}
```

### MenuBarView (Popover Content)

- Dimensions: ~400x500px
- Header with connection status
- Session dropdown selector
- Three-column kanban view
- Click task to show detail panel

### KanbanView

- Horizontal scroll with three columns: Pending, In Progress, Completed
- Column headers with count badges
- Scrollable task lists within each column

### TaskCardView

- Compact card design
- Shows: task ID, subject, active form (if in progress)
- Blocked indicator with dependency info
- Pulse animation for in-progress tasks
- Click to show TaskDetailView

### TaskDetailView

- Sheet/panel overlay
- Full task info: subject, status, description (markdown rendered)
- Blocks/blocked-by relationships
- Note input form to add notes for Claude

### PreferencesView

- Claude directory path (with browse button)
- Notification toggles: task complete, session complete, blocked
- Theme picker: System, Light, Dark

## Theming

Match the web app's "Terminal Luxe" aesthetic:

### Dark Theme

```swift
bgDeep: #08090a
bgSurface: #0d0e10
bgElevated: #131416
bgHover: #1a1b1e
border: #1e2023
textPrimary: #e8e8e8
textSecondary: #8b8d91
textTertiary: #5a5c60
textMuted: #3d3f42
accent: #E86F33        // Claude orange
success: #3ecf8e
warning: #f0b429
```

### Light Theme

```swift
bgDeep: #fafafa
bgSurface: #ffffff
bgElevated: #f5f5f5
bgHover: #efefef
border: #e5e5e5
textPrimary: #171717
textSecondary: #525252
textTertiary: #737373
textMuted: #a3a3a3
```

### Animations

- Pulse effect for in-progress tasks: opacity 0.6-1.0, scale 0.9-1.0, 2s ease-in-out infinite
- Glow effect on accent color for active indicators

## Menu Bar Icon

- Static checkmark icon when idle
- Pulse animation overlay when tasks are in progress
- Right-click menu: Preferences, Quit

## Feature Parity with Web App

| Web App Feature | macOS App Equivalent |
|-----------------|---------------------|
| Live Updates (SSE) | FSEvents file watching |
| Session list | Session dropdown in popover |
| Kanban board | KanbanView with three columns |
| Task details | TaskDetailView sheet |
| Add notes | Note form in TaskDetailView |
| Project filtering | Project dropdown |
| Session filtering | Active/All toggle |
| Search | Search field in header |
| Theme toggle | System/Light/Dark in Preferences |
| Connection status | Animated menu bar icon |

## Future Enhancements (Post-MVP)

- Global keyboard shortcut to show/hide popover
- Task creation from the app
- Drag-and-drop task reordering
- Multiple Claude directory profiles
- Export to Linear/GitHub Issues/Jira

## Success Criteria

1. App launches as menu bar item
2. Popover shows current tasks in kanban format
3. Real-time updates when task files change
4. Can add notes to tasks
5. Notifications fire on configured events
6. Theme matches web app aesthetic
7. Preferences persist across launches
