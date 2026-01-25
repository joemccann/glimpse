# Project Guide: Glimpse

## Purpose

A native macOS menu bar app that displays Claude Code tasks in a Kanban-style popover with real-time file watching and notification support. Shows task status (Pending, In Progress, Completed) from `~/.claude/tasks/`.

## Quick Start

```bash
# Build the app
./scripts/build-app.sh

# Build and install to /Applications
./scripts/build-app.sh --install

# Launch
open build/Glimpse.app
```

## Project Structure

```
claude-task-viewer-macos-bar/
├── Glimpse/                             # Xcode/SPM project
│   ├── Package.swift
│   └── Glimpse/
│       ├── App/                         # Entry point, AppDelegate
│       ├── Views/                       # SwiftUI views
│       ├── Models/                      # Data models (Task, Session, Preferences)
│       ├── Services/                    # TaskManager, FileWatcher, NotificationManager
│       ├── Utilities/                   # Theme colors
│       └── Resources/
│           └── Assets.xcassets/         # App and menu bar icons
├── scripts/
│   ├── build-app.sh                     # Production build script
│   └── generate-menubar-icon.swift      # Menu bar icon generator
├── docs/plans/                          # Design and implementation docs
└── build/                               # Build output (gitignored)
```

## Icon Assets

Icons are pre-generated in `Assets.xcassets/`:

| Asset | Location | Description |
|-------|----------|-------------|
| App Icon | `AppIcon.appiconset/` | Claude orange geometric gem with checkmark (all macOS sizes) |
| Menu Bar | `MenuBarIcon.imageset/` | Black template silhouette (auto dark/light mode) |

To regenerate the menu bar icon:
```bash
swift scripts/generate-menubar-icon.swift
```

## Key Technologies

- **Framework**: SwiftUI + AppKit hybrid
- **File Watching**: FSEvents for real-time updates
- **Data Source**: Direct filesystem access to `~/.claude/tasks/`
- **Build System**: Swift Package Manager
- **Target**: macOS 13+

## Theme

"Terminal Luxe" aesthetic matching Claude's brand:
- **Accent**: `#E86F33` (Claude orange)
- **Dark BG**: `#08090a`
- **Success**: `#3ecf8e`

## Generating Mock Data for Screenshots

When creating screenshots or testing the UI with realistic data, generate mock projects and tasks directly in `~/.claude/`.

### Data Structure

```
~/.claude/
├── tasks/{session-uuid}/           # Task storage
│   ├── 1.json                      # Individual task files
│   ├── 2.json
│   └── ...
└── projects/{encoded-path}/        # Project metadata
    ├── {session-uuid}.jsonl        # Links session to project
    └── sessions-index.json         # Optional: custom names, git branches
```

**Project ID encoding**: Path with `/` replaced by `-`
- `/Users/joemccann/dev/apps/my-app` → `-Users-joemccann-dev-apps-my-app`

### Task JSON Schema

```json
{
  "id": "1",
  "subject": "Implement feature X",
  "description": "Detailed description of the task...",
  "status": "pending|in_progress|completed",
  "activeForm": "Implementing feature X",
  "blocks": ["2", "3"],
  "blockedBy": ["0"]
}
```

### Session Metadata (.jsonl)

```jsonl
{"type":"summary","summary":"Session summary"}
{"type":"custom-title","customTitle":"My Session Name"}
{"slug":"my-session-slug"}
```

### Example: Generate Mock Data Script

```bash
# Create a project directory
PROJECT_ID="-Users-joemccann-dev-apps-my-app"
mkdir -p ~/.claude/projects/$PROJECT_ID

# Create a session with tasks
SESSION_ID="$(uuidgen | tr '[:upper:]' '[:lower:]')"
mkdir -p ~/.claude/tasks/$SESSION_ID

# Create task file
cat > ~/.claude/tasks/$SESSION_ID/1.json << 'EOF'
{
  "id": "1",
  "subject": "Build login form",
  "description": "Create React component with email/password fields and validation.",
  "status": "in_progress",
  "activeForm": "Building login form"
}
EOF

# Link session to project
cat > ~/.claude/projects/$PROJECT_ID/$SESSION_ID.jsonl << EOF
{"type":"custom-title","customTitle":"Auth Implementation"}
{"slug":"auth-impl"}
EOF
```

### Cleanup

To remove mock data after screenshots:
```bash
# Remove specific mock sessions
rm -rf ~/.claude/tasks/{session-uuid}
rm ~/.claude/projects/{project-id}/{session-uuid}.jsonl

# Or remove entire mock projects
rm -rf ~/.claude/projects/-Users-joemccann-dev-apps-mock-project
```

## Aliases

- **cmbp**: Commit changes, pull main, merge main into current branch, bump version, push to GitHub, delete feature branch.
