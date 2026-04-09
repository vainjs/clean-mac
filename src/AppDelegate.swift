import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var viewModel: CleanerViewModel!
    private var iconTimer: Timer?
    private var angle: CGFloat = 0
    private var cancellable: AnyCancellable?

    private func loadMenuBarIcon() -> NSImage? {
        let image = NSImage(named: "menubar-icon") ?? NSImage(systemSymbolName: "leaf.fill", accessibilityDescription: "CleanMac")
        image?.isTemplate = true
        return image
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 确保单实例
        let running = NSWorkspace.shared.runningApplications
        for app in running where app.bundleIdentifier == Bundle.main.bundleIdentifier && app.processIdentifier != ProcessInfo.processInfo.processIdentifier {
            app.activate(options: [])
            NSApp.terminate(nil)
            return
        }

        viewModel = CleanerViewModel()
        viewModel.dismissAction = { [weak self] in
            self?.popover.performClose(nil)
        }
        viewModel.refocusAction = { [weak self] in
            guard let self, self.popover.isShown else { return }
            NSApp.activate(ignoringOtherApps: true)
            self.popover.contentViewController?.view.window?.makeKeyAndOrderFront(nil)
        }

        // 状态栏图标
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            let iconImage = loadMenuBarIcon() ?? NSImage(systemSymbolName: "leaf.fill", accessibilityDescription: "CleanMac")
            button.image = iconImage
            button.action = #selector(togglePopover)
            button.target = self

            // 启用右键点击
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // Popover SwiftUI 内容
        let rootView = MenuBarView(viewModel: viewModel)
        popover = NSPopover()
        popover.behavior = .transient
        popover.delegate = self
        popover.contentViewController = NSHostingController(rootView: rootView)

        // 监听 isCleaning 状态控制图标旋转
        cancellable = viewModel.$isCleaning
            .receive(on: RunLoop.main)
            .sink { [weak self] cleaning in
                guard let self else { return }
                self.popover.behavior = cleaning ? .applicationDefined : .transient
                if cleaning {
                    self.startIconRotation()
                } else {
                    self.stopIconRotation()
                }
            }
    }

    // MARK: - 右键菜单

    private func showRightClickMenu() {
        let menu = NSMenu()
        menu.minimumWidth = 180
        
        let exitItem = NSMenuItem(title: "退出", action: #selector(exitApp), keyEquivalent: "q")
        exitItem.target = self
        exitItem.keyEquivalentModifierMask = .command
        menu.addItem(exitItem)

        guard let button = statusItem.button,
              let window = button.window else { return }
        
        // 获取按钮在屏幕上的位置
        var buttonFrameInScreen = button.convert(button.bounds, to: nil)
        buttonFrameInScreen = window.convertToScreen(buttonFrameInScreen)
        
        // 菜单定位点：按钮左下角往下 10 像素
        let menuLocation = NSPoint(x: buttonFrameInScreen.minX, y: buttonFrameInScreen.minY - 10)
        
        menu.popUp(positioning: nil, at: menuLocation, in: nil)
    }

    @objc private func exitApp() {
        popover.performClose(nil)
        NSApp.terminate(nil)
    }

    // MARK: - 左键 Popover 控制

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        // 检测右键点击
        if let event = NSApp.currentEvent, event.type == .rightMouseUp {
            showRightClickMenu()
            return
        }

        // 左键行为
        if popover.isShown {
            popover.performClose(nil)
        } else {
            // 刷新 SwiftUI 视图确保状态同步
            if let hostingVC = popover.contentViewController as? NSHostingController<MenuBarView> {
                hostingVC.rootView = MenuBarView(viewModel: viewModel)
            }
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            DispatchQueue.main.async {
                button.highlight(true)
            }
        }
    }

    // MARK: - NSPopoverDelegate

    func popoverDidClose(_ notification: Notification) {
        statusItem.button?.highlight(false)
    }

    // MARK: - 菜单栏图标旋转动画

    private func startIconRotation() {
        angle = 0
        iconTimer?.invalidate()
        iconTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.updateRotatingIcon()
        }
    }

    private func stopIconRotation() {
        iconTimer?.invalidate()
        iconTimer = nil
        angle = 0
        statusItem?.button?.image = loadMenuBarIcon() ?? NSImage(systemSymbolName: "leaf.fill", accessibilityDescription: "CleanMac")
    }

    private func updateRotatingIcon() {
        angle += 12
        if angle >= 360 { angle -= 360 }
        guard let button = statusItem?.button else { return }
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        guard let base = NSImage(systemSymbolName: "arrow.triangle.2.circlepath", accessibilityDescription: nil)?
            .withSymbolConfiguration(config) else { return }
        let size = base.size
        let rotated = NSImage(size: size, flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            ctx.translateBy(x: size.width / 2, y: size.height / 2)
            ctx.rotate(by: self.angle * .pi / 180)
            ctx.translateBy(x: -size.width / 2, y: -size.height / 2)
            base.draw(in: rect)
            return true
        }
        rotated.isTemplate = true
        button.image = rotated
    }
}
