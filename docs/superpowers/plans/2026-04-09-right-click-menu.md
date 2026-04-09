# 右键菜单功能实现计划

**Goal:** 为菜单栏图标增加右键点击菜单，提供退出程序入口。

**Architecture:** 在 `NSStatusItem.button` 上通过子类或事件重写监听 `rightMouseDown`，弹出 `NSMenu` 实现右键菜单。左键行为保持不变。

**Tech Stack:** Swift, AppKit (NSStatusItem, NSMenu, NSEvent)

---

## 文件结构

```
src/AppDelegate.swift  # 唯一改动文件
```

---

## Task 1: 添加退出 Action

**文件:**
- 修改: `src/AppDelegate.swift:84` (在 `togglePopover` 方法后添加)

- [ ] **Step 1: 添加 exitApp 方法**

在 `AppDelegate.swift` 末尾（`}` 闭包前）添加：

```swift
    @objc private func exitApp() {
        popover.performClose(nil)
        NSApp.terminate(nil)
    }
}
```

- [ ] **Step 2: 验证编译**

Run: `xcodebuild -project src/CleanMac.xcodeproj -scheme CleanMac -configuration Debug build 2>&1 | grep -E "(error|warning)" | head -20`
Expected: 无 error

- [ ] **Step 3: 提交**

```bash
git add src/AppDelegate.swift && git commit -m "feat: add exitApp action for right-click menu"
```

---

## Task 2: 实现右键菜单

**文件:**
- 修改: `src/AppDelegate.swift`

- [ ] **Step 1: 在 AppDelegate 类中添加 rightMouseDown 方法**

在 `AppDelegate` 类的 `@objc private func togglePopover()` 方法**之前**添加：

```swift
    @objc override func rightMouseDown(with event: NSEvent) {
        let menu = NSMenu()
        let exitItem = NSMenuItem(title: "退出", action: #selector(exitApp), keyEquivalent: "")
        exitItem.target = self
        menu.addItem(exitItem)

        guard let button = statusItem.button else { return }
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: 0), in: button)
    }
```

- [ ] **Step 2: 验证编译**

Run: `xcodebuild -project src/CleanMac.xcodeproj -scheme CleanMac -configuration Debug build 2>&1 | grep -E "(error|warning)" | head -20`
Expected: 无 error

- [ ] **Step 3: 提交**

```bash
git add src/AppDelegate.swift && git commit -m "feat: add right-click menu with exit option"
```
