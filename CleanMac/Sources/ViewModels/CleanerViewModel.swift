import Foundation
import SwiftUI

enum AppState {
    case idle
    case cleaning
    case completed
}

@MainActor
class CleanerViewModel: ObservableObject {
    @Published var appState: AppState = .idle
    @Published var tasks: [CleanTask] = CleanTask.allTasks
    @Published var spaceBefore: String = ""
    @Published var spaceAfter: String = ""
    @Published var currentTaskIndex: Int = 0
    @Published var isCleaning: Bool = false
    @Published var totalLogCount: Int = 0
    var dismissAction: (() -> Void)?
    var refocusAction: (() -> Void)?

    private let service = CleanerService()

    var selectedTasks: [CleanTask] {
        tasks.filter { $0.isSelected }
    }

    var totalSelected: Int {
        selectedTasks.count
    }

    var completedCount: Int {
        tasks.filter { $0.isSelected }.filter {
            if case .completed = $0.status { return true }
            if case .failed = $0.status { return true }
            if case .skipped = $0.status { return true }
            return false
        }.count
    }

    func startCleanup() {
        guard !selectedTasks.isEmpty else { return }
        appState = .cleaning
        isCleaning = true
        currentTaskIndex = 0

        // Reset task states
        for i in tasks.indices {
            if tasks[i].isSelected {
                tasks[i].status = .pending
                tasks[i].logLines = []
            }
        }

        Task.detached { [service, weak self] in
            guard let self else { return }

            let spaceBefore = service.getAvailableDiskSpace()
            await MainActor.run { self.spaceBefore = spaceBefore }

            let tasksCopy = await MainActor.run { self.tasks }
            let selectedIds = tasksCopy.filter { $0.isSelected }.map { $0.id }

            // Run all privileged commands in a single batch (one password prompt)
            let needsPrivileged = selectedIds.contains(.timeMachine) || selectedIds.contains(.cache)
            if needsPrivileged {
                do {
                    try service.runAllPrivilegedCommands(selectedTaskIds: selectedIds)
                } catch CleanerError.userCancelled {
                    await MainActor.run {
                        self.isCleaning = false
                        self.resetToIdle()
                    }
                    return
                } catch {
                    // Best effort — continue with non-privileged tasks
                }
                await MainActor.run {
                    self.refocusAction?()
                }
            }

            // Run individual tasks (non-privileged operations + logging)
            for i in tasksCopy.indices where tasksCopy[i].isSelected {
                await MainActor.run {
                    self.currentTaskIndex = self.completedCount + 1
                    self.tasks[i].status = .inProgress
                }

                let logHandler: @Sendable (String, Bool) -> Void = { text, isWarning in
                    Task { @MainActor in
                        self.tasks[i].logLines.append(LogLine(text, isWarning: isWarning))
                        self.totalLogCount += 1
                    }
                }

                switch tasksCopy[i].id {
                case .timeMachine:
                    service.runTimeMachineCleanup(onLog: logHandler)
                case .cache:
                    service.runCacheCleanup(onLog: logHandler)
                case .devTools:
                    let didWork = service.runDevToolsCleanup(onLog: logHandler)
                    if !didWork {
                        await MainActor.run { self.tasks[i].status = .skipped("未检测到开发工具缓存") }
                        continue
                    }
                case .largeFiles:
                    service.runLargeFileScan(onLog: logHandler)
                }
                await MainActor.run {
                    self.tasks[i].status = .completed
                    self.refocusAction?()
                }
            }

            let spaceAfter = service.getAvailableDiskSpace()
            await MainActor.run {
                self.spaceAfter = spaceAfter
                self.isCleaning = false
                self.appState = .completed
            }
        }
    }

    func resetToIdle() {
        appState = .idle
        isCleaning = false
        for i in tasks.indices {
            tasks[i].status = .pending
            tasks[i].logLines = []
            tasks[i].isSelected = true
        }
        spaceBefore = ""
        spaceAfter = ""
        currentTaskIndex = 0
        totalLogCount = 0
    }
}
