import SwiftUI

struct CleaningView: View {
    @ObservedObject var viewModel: CleanerViewModel
    @State private var isSpinning = false

    var body: some View {
        VStack(spacing: 14) {
            // Header
            HStack(spacing: 6) {
                Text("清理中")
                    .font(.system(size: 15, weight: .semibold))
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.inProgress)
                    .rotationEffect(.degrees(isSpinning ? 360 : 0))
                    .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: isSpinning)
                    .onAppear { isSpinning = true }
            }

            // Progress
            VStack(spacing: 6) {
                ProgressView(
                    value: Double(viewModel.completedCount),
                    total: Double(max(viewModel.totalSelected, 1))
                )
                .tint(Theme.primary)

                HStack {
                    if let current = viewModel.tasks.first(where: {
                        if case .inProgress = $0.status { return true }
                        return false
                    }) {
                        Text(current.name)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("\(viewModel.completedCount)/\(viewModel.totalSelected)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }

            // Log area
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 3) {
                        ForEach(viewModel.tasks.filter { $0.isSelected }) { task in
                            ForEach(task.logLines) { line in
                                LogItemView(line: line, status: task.status)
                            }
                        }
                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .padding(10)
                }
                .frame(maxHeight: 180)
                .background(Color.primary.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onChange(of: viewModel.totalLogCount) { _ in
                    withAnimation {
                        proxy.scrollTo("bottom")
                    }
                }
            }
        }
    }
}
