import Foundation

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
