# CleanMac

macOS menu bar app for system cleanup. Wraps `clean_mac.command` shell script in a native SwiftUI interface.

## Quick Start

```bash
cd CleanMac && xcodegen generate   # Generate .xcodeproj
# Open CleanMac.xcodeproj in Xcode, or:
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project CleanMac/CleanMac.xcodeproj -scheme CleanMac -configuration Debug build
```

## Architecture

- **Pattern**: MVVM (ViewModel drives 3-state UI: idle → cleaning → completed)
- **Menu bar**: NSStatusItem + NSPopover (not MenuBarExtra — needed for icon rotation)
- **Privilege escalation**: Batched osascript (single password prompt for all sudo tasks)
- **Build**: XcodeGen (`CleanMac/project.yml`), macOS 13+, Swift 5.9

## Project Layout

```
CleanMac/Sources/
├── CleanMacApp.swift          # @main, NSApplicationDelegateAdaptor
├── AppDelegate.swift          # NSStatusItem, NSPopover, icon rotation timer
├── Theme.swift                # Color.theme (primary/inProgress/warning)
├── Models/CleanTask.swift     # TaskId enum, CleanTask, TaskStatus
├── Services/CleanerService.swift  # Shell execution, batch privileged commands
├── ViewModels/CleanerViewModel.swift  # State machine, task orchestration
└── Views/                     # MenuBarView, IdleView, CleaningView, CompletedView, TaskRowView, LogItemView
```

## Icon Assets

- **App icon source**: `CleanMac/icon-source.svg` (green gradient + white leaf.fill potrace path)
- **App icon PNGs**: `CleanMac/Sources/Assets.xcassets/AppIcon.appiconset/` (7 sizes: 16-1024)
- **Menu bar icon**: SF Symbol `leaf.fill` loaded at runtime via `NSImage(systemSymbolName:)`, no pre-rendered assets needed

## Conventions

- UI text in Chinese (zh-CN)
- Task IDs use `TaskId` enum (not strings)
- Colors via `Color.theme.primary` / `.inProgress` / `.warning`
- Read stderr pipe **before** `waitUntilExit()` (prevents deadlock)
- Popover behavior: `.transient` when idle, `.applicationDefined` during cleaning

## Key Files

| What | Where |
|------|-------|
| Design spec | `docs/superpowers/specs/2026-03-11-cleanmac-macos-app-design.md` |
| Implementation plan | `docs/superpowers/plans/2026-03-12-cleanmac-macos-app.md` |
| Original script | `clean_mac.command` |
