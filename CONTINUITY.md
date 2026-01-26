# Continuity Ledger

## Goal
Glimpse - A native macOS menu bar app that displays Claude Code tasks in a Kanban-style popover with real-time file watching and notification support.

**Success criteria:**
- Menu bar icon with popover UI
- Kanban view (Pending/In Progress/Completed)
- Real-time file watching via FSEvents
- Project filtering (by folder name)
- Session picker and search
- Task detail view with note adding
- macOS notifications
- Preferences window

## Constraints/Assumptions
- macOS 13+ required
- SwiftUI + AppKit hybrid approach
- Direct filesystem access to ~/.claude/tasks/
- No server component (unlike web app)
- SPM-based build (not Xcode project file initially)

## Key Decisions
| Decision | Choice | Rationale |
|----------|--------|-----------|
| Framework | SwiftUI + AppKit | Native performance, best macOS integration |
| UI Structure | NSPopover | Natural menu bar UX, transient behavior |
| Data Access | FSEvents file watching | Efficient, low overhead |
| Build System | Swift Package Manager | Simpler initial setup |

## State

### Done
- Glimpse branding complete
- Project filtering feature (v1.3.0)
- Twitter banner marketing asset generated.

### Now
- Reviewing UI components for final polish.

### Next
- Finalize documentation and prepare for release
- Commit and merge project filtering feature

## Open Questions
- None currently

## Working Set
- Design doc: `docs/plans/2025-01-25-macos-menu-bar-app-design.md`
- Implementation plan: `docs/plans/2025-01-25-macos-menu-bar-implementation.md`
- Build script: `scripts/build-app.sh`
- Menu bar icon script: `scripts/generate-menubar-icon.swift`
- App icons: `Glimpse/Glimpse/Resources/Assets.xcassets/`