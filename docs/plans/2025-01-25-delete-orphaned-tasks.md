# Delete Orphaned Tasks Feature

> **Note:** This plan was written when the app was named "ClaudeTaskViewer". The project has since been renamed to "Glimpse". File paths like `ClaudeTaskViewer/...` now correspond to `Glimpse/...`.

## Overview

Add the ability to delete orphaned or old task sessions from `~/.claude/tasks/`. Users can identify orphaned sessions by:
- Age (> 30 days old)
- No matching project in `~/.claude/projects/`
- All tasks completed
- Manual user determination

## UI Design

**Location:** Session picker dropdown in MenuBarView

**Behavior:**
1. Each session row shows a delete button (trash icon) on hover
2. Sessions are visually marked if they meet orphan criteria (faded, badge, or indicator)
3. Clicking delete shows a confirmation dialog with session details
4. After confirmation, the session folder is deleted from `~/.claude/tasks/{session-id}/`

## Recommendations

### R1: Add Orphan Detection to Session Model
Extend the `Session` model to include:
- `isOrphan: Bool` computed property based on criteria
- `daysSinceModified: Int` computed from `modifiedAt`
- `hasMatchingProject: Bool` flag from SessionManager

### R2: Add Delete Capability to TaskManager
Add a method to delete a session's task folder:
```swift
func deleteSession(sessionId: String) throws
```

### R3: Create Session Row View with Delete Button
Replace inline session picker with a custom view showing:
- Session name
- Orphan indicator (if applicable)
- Delete button (trash icon) on hover/always

### R4: Create Confirmation Dialog
A sheet/alert showing:
- Session name
- Task count
- Why it's considered orphan (if applicable)
- Cancel / Delete buttons

### R5: Update MenuBarView
Integrate the new session row view and confirmation flow.

---

## Tasks

### Task 1: Extend Session Model with Orphan Detection
**Files:** `ClaudeTaskViewer/Models/Session.swift`

Add computed properties:
- `daysSinceModified: Int`
- `isAllCompleted: Bool`
- `isOrphan: Bool` (requires `hasMatchingProject` to be set)

Add stored property:
- `hasMatchingProject: Bool` (set by SessionManager)

### Task 2: Update SessionManager to Detect Orphans
**Files:** `ClaudeTaskViewer/Services/SessionManager.swift`

- Check if each session has a matching `.jsonl` file in projects
- Set `hasMatchingProject` flag on each Session
- Add `deleteSession(sessionId:)` method that removes the folder

### Task 3: Create SessionRowView Component
**Files:** `ClaudeTaskViewer/Views/SessionRowView.swift` (new)

SwiftUI view for a session row:
- Display session name with truncation
- Show orphan badge/indicator if `isOrphan`
- Delete button (SF Symbol `trash`) appears on hover
- Tap triggers delete confirmation

### Task 4: Create DeleteConfirmationView
**Files:** `ClaudeTaskViewer/Views/DeleteConfirmationView.swift` (new)

Confirmation sheet showing:
- Session name
- Number of tasks (pending/in-progress/completed breakdown)
- Orphan reason (if applicable)
- Cancel and Delete Permanently buttons

### Task 5: Update MenuBarView with New Session Picker
**Files:** `ClaudeTaskViewer/Views/MenuBarView.swift`

- Replace standard Picker with custom session list
- Show SessionRowView for each session
- Handle delete confirmation flow
- Refresh after deletion

### Task 6: Add Unit Tests
**Files:** `ClaudeTaskViewerTests/SessionDeleteTests.swift` (new)

Test cases:
- `testDeleteSessionRemovesFolder`
- `testOrphanDetectionByAge`
- `testOrphanDetectionNoProject`
- `testOrphanDetectionAllCompleted`

### Task 7: Update Documentation
**Files:** `README.md`, `ClaudeTaskViewer/README.md`

Document the new feature in the README.

---

## Execution Order

Tasks 1-2 can run in parallel (model + service changes)
Tasks 3-4 can run in parallel (new views)
Task 5 depends on 1-4 (integration)
Task 6 can run in parallel with 3-5 (tests)
Task 7 runs last (docs)

```
[1: Session Model] ─┬─> [5: MenuBarView Integration] ─> [7: Docs]
[2: SessionManager] ┘           ↑
[3: SessionRowView] ────────────┤
[4: DeleteConfirmationView] ────┘
[6: Tests] ─────────────────────────────────────────────> [7: Docs]
```
