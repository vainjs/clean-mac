import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: CleanerViewModel

    var body: some View {
        Group {
            switch viewModel.appState {
            case .idle:
                IdleView(viewModel: viewModel)
            case .cleaning:
                CleaningView(viewModel: viewModel)
            case .completed:
                CompletedView(viewModel: viewModel)
            }
        }
        .padding(16)
        .frame(width: 300)
    }
}
