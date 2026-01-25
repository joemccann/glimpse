# Glimpse

A native macOS menu bar app for monitoring Claude Code tasks in real-time.

## Features

- **Menu bar integration** — Lives in your menu bar, no dock icon
- **Kanban board** — Visual columns for Pending, In Progress, and Completed
- **Real-time updates** — FSEvents file watching for instant changes
- **Session management** — Filter by session or view all tasks
- **Delete orphaned sessions** — Clean up old, completed, or orphaned task sessions
- **Search** — Find tasks by subject or description
- **Task details** — View dependencies, descriptions, and add notes
- **Notifications** — Optional alerts for task completion
- **Theme support** — System, Light, or Dark mode

## Requirements

- macOS 13.0 (Ventura) or later
- Swift 5.9+

## Building

### Debug build

```bash
swift build
```

### Release build

```bash
swift build -c release
```

Binary location: `.build/release/Glimpse`

### Run directly

```bash
swift run
```

## Running Tests

```bash
swift test
```

## Architecture

```
Glimpse/
├── App/
│   ├── GlimpseApp.swift             # @main entry point
│   └── AppDelegate.swift            # Menu bar setup, popover management
│
├── Models/
│   ├── Task.swift                   # Task model with status enum
│   ├── Session.swift                # Session with task counts
│   └── Preferences.swift            # App settings model
│
├── Views/
│   ├── MenuBarView.swift            # Main popover content
│   ├── KanbanView.swift             # Three-column task layout
│   ├── TaskCardView.swift           # Individual task cards
│   ├── TaskDetailView.swift         # Detail sheet with notes
│   ├── SessionRowView.swift         # Session list row with delete button
│   ├── DeleteConfirmationView.swift # Delete confirmation dialog
│   └── PreferencesView.swift        # Settings window
│
├── Services/
│   ├── TaskManager.swift            # Load/save tasks from filesystem
│   ├── SessionManager.swift         # Load session metadata
│   ├── FileWatcher.swift            # FSEvents-based file monitoring
│   └── NotificationManager.swift    # macOS notifications
│
├── Utilities/
│   └── Theme.swift                  # Terminal Luxe color palette
│
└── Resources/
    ├── Info.plist                   # LSUIElement for menu bar app
    └── Assets.xcassets/             # App and menu bar icons
```

## Key Components

### AppDelegate

Manages the menu bar status item and NSPopover. Handles left-click (toggle popover) and right-click (context menu) separately.

### FileWatcher

Uses FSEvents to monitor `~/.claude/tasks/` for changes. When files are added, modified, or deleted, it triggers a callback to reload the data.

### TaskManager

Reads task JSON files from session directories. Supports loading tasks for a specific session or all tasks across sessions.

### SessionManager

Scans the tasks directory for sessions and enriches them with metadata from `~/.claude/projects/` (custom titles, slugs, git branches). Also handles:
- **Orphan detection** — Identifies sessions older than 30 days, without matching projects, or with all tasks completed
- **Session deletion** — `deleteSession(sessionId:)` removes the session folder from `~/.claude/tasks/`

## Orphan Detection

Sessions are automatically marked as "orphaned" based on these criteria:

| Condition | Property | Description |
|-----------|----------|-------------|
| Age > 30 days | `daysSinceModified` | Session folder hasn't been modified in over 30 days |
| No project match | `hasMatchingProject` | No `.jsonl` file exists in `~/.claude/projects/` for this session |
| All completed | `isAllCompleted` | Every task in the session has `status: completed` |

The `Session.isOrphan` computed property returns `true` if any of these conditions are met. The `Session.orphanReason` property provides a human-readable explanation.

## Data Source

The app reads from:
- `~/.claude/tasks/{session-id}/*.json` — Task files
- `~/.claude/projects/{project}/*.jsonl` — Session metadata
- `~/.claude/projects/{project}/sessions-index.json` — Session index

## Configuration

Preferences are stored in UserDefaults via `@AppStorage`:

| Setting | Key | Default |
|---------|-----|---------|
| Claude Directory | `claudeDirectory` | `~/.claude` |
| Notify on Task Complete | `notifyOnTaskComplete` | `true` |
| Notify on Session Complete | `notifyOnSessionComplete` | `true` |
| Notify on Blocked | `notifyOnBlocked` | `false` |
| Theme | `theme` | `system` |

## License

MIT
