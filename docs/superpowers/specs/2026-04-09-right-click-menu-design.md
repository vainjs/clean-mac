# 右键菜单功能设计

## 概述

为菜单栏图标增加右键点击菜单，提供退出程序入口。

## 设计决策

- **样式**: 简洁文本菜单，无图标
- **菜单位置**: 左侧与图标对齐，菜单栏下方弹出
- **右键触发**: 重写 `rightMouseDown` 而非设置 `.menu`（避免影响左键行为）
- **退出流程**: 先关闭 popover，再退出程序

## 实现方案

### 文件改动

仅修改 `src/AppDelegate.swift`。

### 核心实现

1. **右键事件监听**: 重写 `NSStatusItem.button` 的 `rightMouseDown`
2. **菜单创建**: 创建 `NSMenu`，单一菜单项「退出」
3. **菜单位置**: 使用 `NSMenu.popUp(positioning:at:in:)`，定位到图标左下角
4. **退出处理**: 关闭 popover 后调用 `NSApp.terminate(nil)`

### 代码结构

```swift
// 新增: 右键菜单
private func setupRightClickMenu() {
    let menu = NSMenu()
    menu.addItem(NSMenuItem(title: "退出", action: #selector(exitApp), keyEquivalent: ""))
    menu.items.first?.target = self
    // 存储备用（通过 button 访问）
}

// 新增: 右键事件处理
override func rightMouseDown(with event: NSEvent) {
    let menu = NSMenu()
    menu.addItem(NSMenuItem(title: "退出", action: #selector(exitApp), keyEquivalent: ""))
    menu.items.first?.target = self
    statusItem.button?.performDragRectEdge(menu, with: event, edge: .minY)
}

// 修改: togglePopover 保持左键原有行为不变
```

### 退出 Action

```swift
@objc private func exitApp() {
    popover.performClose(nil)
    NSApp.terminate(nil)
}
```

## 验收标准

- [ ] 右键点击菜单栏图标，菜单在图标下方弹出
- [ ] 左键点击图标仍正常显示/隐藏 popover
- [ ] 点击「退出」菜单项，popover 关闭后程序退出
