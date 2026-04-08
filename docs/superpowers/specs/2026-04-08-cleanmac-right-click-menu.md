# CleanMac 右键上下文菜单 — 设计

## 概述

为菜单栏图标增加右键上下文菜单，符合 macOS 菜单栏应用惯例。

## 交互行为

- **左键点击**：弹出完整面板（现有行为，不变）
- **右键点击**：弹出 `NSMenu` 上下文菜单

## 菜单项

| 菜单项 | Action |
|--------|--------|
| 关于 CleanMac | `NSApplication.orderFrontStandardAboutPanel()` |
| 分隔线 | — |
| 退出 CleanMac | `NSApplication.terminate(nil)` |

## 实现方案

### 新增文件

**`src/StatusBarButtonView.swift`**

自定义 `NSView`，覆盖在 `NSStatusBarButton` 之上，拦截鼠标事件：

- `rightMouseDown` → 弹出 `NSMenu`
- `mouseUp` → 转发左键事件给原有的 `togglePopover`

### AppDelegate 改动

- 将 `statusItem.button` 替换为 `StatusBarButtonView` 实例
- 左键事件通过 `StatusBarButtonView.mouseUp` 转发，仍调用 `togglePopover`
- 右键事件由 `StatusBarButtonView.rightMouseDown` 处理，弹出 `NSMenu`

### 文件变更

| 操作 | 文件 |
|------|------|
| 新增 | `src/StatusBarButtonView.swift` |
| 修改 | `src/AppDelegate.swift` |
