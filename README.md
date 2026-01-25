# Glimpse

**A native macOS menu bar app for Claude Code tasks**

Monitor your Claude Code tasks in real-time with a sleek Kanban-style popover. No dock icon, no clutter - just glance at your menu bar.

![Glimpse - Kanban task viewer for Claude Code](.github/assets/glimpse-banner.png)

## Features

- **Menu bar native** - Lives quietly in your menu bar with an orange gem icon
- **Kanban board** - Visual columns for Pending, In Progress, and Completed
- **Real-time updates** - FSEvents file watching for instant changes
- **Project filtering** - Filter tasks by project, then optionally by session
- **Session picker** - Switch between sessions or view all tasks at once
- **Task details** - View descriptions, dependencies, and add notes
- **Notifications** - Optional alerts when tasks or sessions complete
- **Theme support** - System, Light, or Dark mode

## Requirements

- macOS 13.0 (Ventura) or later

## Installation

### Build from source

```bash
git clone https://github.com/your-username/glimpse.git
cd glimpse
./scripts/build-app.sh --install
```

This builds a production `.app` bundle and installs it to `/Applications`.

### Build only

```bash
./scripts/build-app.sh
```

The app bundle will be at `build/Glimpse.app`.

## Usage

1. Launch Glimpse - an orange gem icon appears in your menu bar
2. **Left-click** the icon to open the Kanban popover
3. Use the **project picker** to filter by project (shows folder names)
4. Use the **session picker** to filter by session within that project
5. Click any task card to view details and add notes
6. **Right-click** for the context menu (Preferences, Quit)

### Preferences

Access via right-click menu or **Cmd + ,**:

| Setting | Description |
|---------|-------------|
| Claude Directory | Path to your `.claude` folder (default: `~/.claude`) |
| Notifications | Toggle alerts for task/session completion |
| Theme | System, Light, or Dark mode |

## Development

```bash
cd Glimpse
swift run
```

### Run tests

```bash
swift test
```

### Project structure

```
Glimpse/
├── Package.swift
├── Glimpse/
│   ├── App/          # AppDelegate, entry point
│   ├── Models/       # Task, Session, Preferences
│   ├── Views/        # SwiftUI views
│   └── Services/     # TaskManager, FileWatcher
└── GlimpseTests/
```

## How it works

Claude Code stores tasks in `~/.claude/tasks/`. Glimpse watches this directory using FSEvents and updates the UI in real-time - no polling required.

## Acknowledgments

Glimpse was inspired by [claude-task-viewer](https://github.com/L1AD/claude-task-viewer), an Electron-based Claude Code task viewer. This project reimagines the concept as a lightweight native macOS menu bar app.

## License

MIT
