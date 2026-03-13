import SwiftUI

struct CompletedView: View {
    @ObservedObject var viewModel: CleanerViewModel

    var body: some View {
        VStack(spacing: 14) {
            // Header
            HStack(spacing: 6) {
                Text("清理完成")
                    .font(.system(size: 15, weight: .semibold))
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 15))
                    .foregroundColor(Theme.primary)
            }

            // Space comparison
            HStack(spacing: 0) {
                VStack(spacing: 2) {
                    Text("清理前")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text(viewModel.spaceBefore)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.primary)

                VStack(spacing: 2) {
                    Text("清理后")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text(viewModel.spaceAfter)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.primary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 10)
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Log summary
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 3) {
                    ForEach(viewModel.tasks.filter { $0.isSelected }) { task in
                        ForEach(task.logLines) { line in
                            LogItemView(line: line, status: task.status)
                        }
                    }
                }
                .padding(10)
            }
            .frame(maxHeight: 200)
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Button {
                viewModel.resetToIdle()
                viewModel.dismissAction?()
            } label: {
                Text("完成")
                    .font(.system(size: 13, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.primary)
        }
    }
}
