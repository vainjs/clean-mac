import Foundation

class CleanerService {
    private let homeDir: String

    init() {
        self.homeDir = NSHomeDirectory()
    }

    // MARK: - Disk Space

    func getAvailableDiskSpace() -> String {
        let url = URL(fileURLWithPath: "/")
        guard let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]),
              let bytes = values.volumeAvailableCapacityForImportantUsage else {
            return "?"
        }
        let gb = Double(bytes) / 1_000_000_000.0
        return String(format: "%.1f G", gb)
    }

    // MARK: - Batch Privileged Commands (single password prompt)

    func runAllPrivilegedCommands(selectedTaskIds: [TaskId]) throws {
        var cmds: [String] = []

        if selectedTaskIds.contains(.timeMachine) {
            cmds.append("tmutil thinlocalsnapshots / 1000000000000 4 2>/dev/null || true")
        }

        if selectedTaskIds.contains(.cache) {
            for dir in ["/Library/Caches/com.apple.Safari", "/Library/Caches/com.apple.dt.Xcode", "/Library/Caches/Homebrew"] {
                cmds.append("rm -rf '\(dir)/'* 2>/dev/null || true")
            }
            cmds.append("find /private/var/log -name '*.log' -mtime +7 -delete 2>/dev/null || true")
        }

        if !cmds.isEmpty {
            try runPrivileged(cmds.joined(separator: " ; "))
        }
    }

    // MARK: - Task 1: Time Machine Snapshots

    func runTimeMachineCleanup(onLog: @Sendable (String, Bool) -> Void) {
        onLog("正在清理 Time Machine 本地快照...", false)
        onLog("✓ 快照清理完成", false)
    }

    // MARK: - Task 2: System Cache and Logs

    func runCacheCleanup(onLog: @Sendable (String, Bool) -> Void) {
        // User cache — user-owned, no sudo needed
        onLog("正在清理用户缓存...", false)
        let userCachePath = "\(homeDir)/Library/Caches"
        if let contents = try? FileManager.default.contentsOfDirectory(atPath: userCachePath) {
            for item in contents {
                let fullPath = "\(userCachePath)/\(item)"
                try? FileManager.default.removeItem(atPath: fullPath)
            }
        }
        onLog("✓ 用户缓存已清理", false)

        onLog("正在清理系统缓存和旧日志...", false)
        onLog("✓ 系统缓存已清理（仅安全目录）", false)

        // User logs — no sudo needed
        let userLogsPath = "\(homeDir)/Library/Logs"
        _ = runShell("/usr/bin/find", arguments: [userLogsPath, "-type", "f", "-mtime", "+7", "-delete"])
        onLog("✓ 7 天前的旧日志已清理", false)
    }

    // MARK: - Task 3: Developer Tool Cache

    func runDevToolsCleanup(onLog: @Sendable (String, Bool) -> Void) -> Bool {
        var didSomething = false

        // Homebrew
        let brewPaths = ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]
        if let brewPath = brewPaths.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) {
            onLog("正在清理 Homebrew 缓存...", false)
            let process = Process()
            process.executableURL = URL(fileURLWithPath: brewPath)
            process.arguments = ["cleanup", "--prune=all"]
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            try? process.run()
            process.waitUntilExit()
            onLog("✓ Homebrew 缓存已清理", false)
            didSomething = true
        }

        // npm
        let npmCache = "\(homeDir)/.npm/_cacache"
        if FileManager.default.fileExists(atPath: npmCache) {
            onLog("正在清理 npm 缓存...", false)
            try? FileManager.default.removeItem(atPath: npmCache)
            onLog("✓ npm 缓存已清理", false)
            didSomething = true
        }

        // pip
        let pipCache = "\(homeDir)/Library/Caches/pip"
        if FileManager.default.fileExists(atPath: pipCache) {
            onLog("正在清理 pip 缓存...", false)
            try? FileManager.default.removeItem(atPath: pipCache)
            onLog("✓ pip 缓存已清理", false)
            didSomething = true
        }

        if !didSomething {
            onLog("未检测到开发工具缓存，已跳过", false)
        }
        return didSomething
    }

    // MARK: - Task 4: Large File Scan

    func runLargeFileScan(onLog: @Sendable (String, Bool) -> Void) {
        onLog("正在扫描大文件...", false)
        let downloadsPath = "\(homeDir)/Downloads"
        let result = runShell(
            "/usr/bin/find",
            arguments: [downloadsPath, "-type", "f", "-mtime", "+7", "-size", "+200M"]
        )
        let files = result.split(separator: "\n").map(String.init).filter { !$0.isEmpty }

        if files.isEmpty {
            onLog("未发现可清理的大文件", false)
        } else {
            onLog("找到 \(files.count) 个大文件（>200MB，7天前）：", true)
            for file in files {
                let url = URL(fileURLWithPath: file)
                let name = url.lastPathComponent
                if let attrs = try? FileManager.default.attributesOfItem(atPath: file),
                   let size = attrs[.size] as? UInt64
                {
                    let sizeStr = ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
                    onLog("  \(sizeStr)\t\(name)", true)
                }
            }
        }
        onLog("提示: 请手动检查 ~/Downloads 文件夹", true)
    }

    // MARK: - Shell Helpers

    private func runShell(_ command: String, arguments: [String] = []) -> String {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe
        try? process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func runPrivileged(_ command: String) throws {
        let escaped = command.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let script = "do shell script \"\(escaped)\" with administrator privileges"
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        let errPipe = Pipe()
        process.standardError = errPipe
        try process.run()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        if process.terminationStatus != 0 {
            let errMsg = String(data: errData, encoding: .utf8) ?? "Unknown error"
            if errMsg.contains("User canceled") || errMsg.contains("-128") {
                throw CleanerError.userCancelled
            }
            throw CleanerError.taskFailed(errMsg)
        }
    }
}

enum CleanerError: LocalizedError {
    case userCancelled
    case taskFailed(String)

    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "用户取消了授权"
        case .taskFailed(let msg):
            return "任务失败: \(msg)"
        }
    }
}
