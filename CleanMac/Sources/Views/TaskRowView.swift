import SwiftUI

struct TaskRowView: View {
    @Binding var task: CleanTask

    var body: some View {
        Button {
            task.isSelected.toggle()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: task.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundColor(task.isSelected ? Theme.primary : .secondary.opacity(0.5))
                    .frame(width: 20)

                Text(task.name)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
