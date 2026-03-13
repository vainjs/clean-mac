import Foundation

enum TaskId: String, CaseIterable {
    case timeMachine = "timemachine"
    case cache = "cache"
    case devTools = "devtools"
    case largeFiles = "largefiles"
}

enum TaskStatus: Equatable {
    case pending
    case inProgress
    case completed
    case failed(String)
    case skipped(String)
}

struct LogLine: Identifiable {
    let id = UUID()
    let text: String
    let isWarning: Bool

    init(_ text: String, isWarning: Bool = false) {
        self.text = text
        self.isWarning = isWarning
    }
}

struct CleanTask: Identifiable {
    let id: TaskId
    let name: String
    let requiresSudo: Bool
    var isSelected: Bool = true
    var status: TaskStatus = .pending
    var logLines: [LogLine] = []

    static let allTasks: [CleanTask] = [
        CleanTask(id: .timeMachine, name: "Time Machine 快照清理", requiresSudo: true),
        CleanTask(id: .cache, name: "系统缓存和日志", requiresSudo: true),
        CleanTask(id: .devTools, name: "开发工具缓存", requiresSudo: false),
        CleanTask(id: .largeFiles, name: "大文件检查", requiresSudo: false),
    ]
}
