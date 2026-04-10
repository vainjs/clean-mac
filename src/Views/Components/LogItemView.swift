import SwiftUI

struct LogItemView: View {
    let line: LogLine
    let status: TaskStatus

    private var textColor: Color {
        if line.isWarning {
            return Theme.warning
        }
        switch status {
        case .completed:
            return .primary.opacity(0.7)
        case .inProgress:
            return .primary.opacity(0.85)
        case .failed:
            return Theme.warning
        default:
            return .secondary
        }
    }

    var body: some View {
        Text(line.text)
            .font(.system(size: 11, design: .monospaced))
            .foregroundColor(textColor)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
    }
}
