import SwiftUI

struct IdleView: View {
    @ObservedObject var viewModel: CleanerViewModel

    var body: some View {
        VStack(spacing: 16) {
            // Header
            Text("CleanMac")
                .font(.system(size: 15, weight: .semibold))
                .padding(.bottom, 2)

            // Task list
            VStack(spacing: 0) {
                ForEach($viewModel.tasks) { $task in
                    TaskRowView(task: $task)
                    if task.id != viewModel.tasks.last?.id {
                        Divider()
                            .padding(.leading, 36)
                    }
                }
            }
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Start button
            Button {
                viewModel.startCleanup()
            } label: {
                Text("开始清理")
                    .font(.system(size: 13, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.primary)
            .disabled(viewModel.selectedTasks.isEmpty)
        }
    }
}
