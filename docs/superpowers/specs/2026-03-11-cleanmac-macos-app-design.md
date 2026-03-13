# CleanMac macOS Menu Bar App - Design Spec

## Overview

Wrap the existing `clean_mac.command` shell script into a native macOS menu bar app. The app sits in the system menu bar, provides a dropdown panel for selecting cleanup tasks, displays real-time logs during cleanup, and shows before/after disk space comparison on completion.

## Application Form

- **Type**: macOS Menu Bar App (no Dock icon, `LSUIElement = true`)
- **Tech stack**: Swift 5.9 + SwiftUI, NSStatusItem + NSPopover (replaced MenuBarExtra for icon animation support)
- **Architecture**: MVVM, no external dependencies
- **Deployment target**: macOS 13 Ventura+
- **Build system**: XcodeGen (`project.yml`)

## App Icon

- **Background**: Diagonal gradient (`#5ec97e` top-left → `#46B065` center → `#3a9454` bottom-right), with radial glow overlay (top-left) and bottom shadow
- **Subject**: White SF Symbol `leaf.fill` silhouette (potrace-traced vector path), full opacity
- **Details**: Small white dust particles at bottom-left (3 circles, decreasing opacity)
- **Source**: `CleanMac/icon-source.svg` (1024x1024 SVG with embedded potrace path)
- **Sizes**: Full icon set per Apple HIG (1024/512/256/128/64/32/16)

## Menu Bar Icon

- SF Symbol `leaf.fill` via `NSImage(systemSymbolName:)`, template rendering
- 18x18 (1x) and 36x36 (2x) pre-rendered PNGs in `MenuBarIcon.imageset`
- During cleanup: switches to rotating `arrow.triangle.2.circlepath` icon (Timer at 0.05s, 12 deg/tick via CGContext rotation)

## Panel UI

Uses NSPopover (replaced MenuBarExtra for icon animation control). Popover behavior switches dynamically: `.transient` in idle/completed, `.applicationDefined` during cleaning (prevents auto-close during auth dialogs).

### Idle State

- Title: "CleanMac"
- 4 checkboxes (TaskRowView), all checked by default:
  1. Time Machine 快照清理
  2. 系统缓存与日志
  3. 开发工具缓存
  4. 大文件扫描
- "开始清理" button (disabled when no tasks selected)

### Cleaning State

- Progress bar + step counter (dynamic, based on number of checked tasks)
- Real-time scrolling log area:
  - `✓` completed (theme green `#46B065`)
  - `›` in progress (system blue `#007AFF`)
  - `·` pending (gray)
- Menu bar icon shows spinning animation

### Completed State

- Disk space comparison: before → after
- Released amount highlighted in `#46B065`
- Scrollable log summary; warnings in system orange `#FF9500`
- "完成" button: resets state to idle, closes popover

## Theme Colors

| Role | Color |
|------|-------|
| Primary / buttons / checkboxes / success | `#46B065` |
| In progress | `#007AFF` (system blue) |
| Warning | `#FF9500` (system orange) |
| Text primary | system label |
| Text secondary | system secondary label |

## Cleanup Tasks

Ported from existing `clean_mac.command` script, split into independent tasks:

1. **Time Machine snapshots** — `tmutil thinlocalsnapshots / 1000000000000 4`
2. **System cache and logs**:
   - User cache: `~/Library/Caches/*`
   - System cache (safe dirs): Safari, Xcode, Homebrew
   - Old logs (>7 days): `/private/var/log/*.log`, `~/Library/Logs`
3. **Developer tool cache**:
   - Homebrew: `brew cleanup --prune=all`
   - npm: `~/.npm/_cacache`
   - pip: `~/Library/Caches/pip`
4. **Large file scan** — find files in `~/Downloads` >200MB and >7 days old; report only, do not delete

Each subtask is conditional: skip if the tool is not installed (e.g. `brew` not found) or cache directory does not exist. Matches existing script behavior.

## Error Handling

- If user cancels the password dialog: abort cleanup, return to idle state
- If a task fails mid-execution: log the error, mark task as failed, continue with remaining tasks
- Failed tasks show error message in log with warning color (`#FF9500`)

## Privilege Escalation

- Uses `osascript -e 'do shell script "..." with administrator privileges'`
- All privileged commands (Time Machine + cache cleanup) batched into single osascript call = **single password prompt**
- Popover behavior switches to `.applicationDefined` during auth to prevent auto-close
- `refocusAction` callback re-focuses popover after auth dialog dismisses
- Only tasks requiring elevated privileges use this path; user-space tasks run directly

## Execution

- Shell commands executed via `Process` (Foundation)
- Each task's stdout/stderr piped back to UI in real-time via `Pipe` + `readabilityHandler`
- Before and after cleanup: read available disk space via `df -h /`

## Project Structure

```
CleanMac/
├── project.yml                  # XcodeGen spec
├── icon-source.svg              # App icon SVG source (leaf.fill potrace path)
├── Sources/
│   ├── CleanMacApp.swift        # @main entry, NSApplicationDelegateAdaptor
│   ├── AppDelegate.swift        # NSStatusItem, NSPopover, icon rotation
│   ├── Theme.swift              # Color.theme extension + typealias
│   ├── Models/
│   │   └── CleanTask.swift      # TaskId enum, CleanTask, TaskStatus, LogLine
│   ├── Services/
│   │   └── CleanerService.swift # Shell execution, batch privileged commands
│   ├── ViewModels/
│   │   └── CleanerViewModel.swift # AppState, task scheduling, dismiss/refocus
│   ├── Views/
│   │   ├── MenuBarView.swift    # 3-state container (idle/cleaning/completed)
│   │   ├── IdleView.swift       # Task selection + start button
│   │   ├── CleaningView.swift   # Progress bar + scrolling logs
│   │   ├── CompletedView.swift  # Results + done button
│   │   ├── TaskRowView.swift    # Checkbox row component
│   │   └── LogItemView.swift    # Log line component
│   └── Assets.xcassets/
│       └── AppIcon.appiconset/  # 7 PNG sizes + Contents.json
└── build/
```

## Key Decisions

- **NSStatusItem+NSPopover over MenuBarExtra**: Switched from MenuBarExtra because it doesn't support menu bar icon animation (TimelineView/Timer-driven @Published don't trigger label redraws). NSStatusItem allows direct `button.image` manipulation for rotation.
- **Batched privileged commands**: All sudo-requiring tasks consolidated into single `osascript` call to avoid multiple password prompts.
- **Popover behavior switching**: `.transient` ↔ `.applicationDefined` prevents popover from auto-closing during auth dialogs.
- **Pipe deadlock fix**: Read stderr pipe data before `waitUntilExit()` to prevent process deadlock.
- **TaskId enum over strings**: Compile-time safety for task identification, exhaustive switch without default.
- **osascript over SMJobBless**: Simpler to implement, no helper tool installation required.
- **Report-only for large files**: The scan step lists large files but does not delete them, matching the original script behavior.
- **App icon leaf.fill**: Uses SF Symbol `leaf.fill` shape (potrace-traced to SVG) for consistency between app icon and menu bar icon.
