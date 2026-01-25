import SwiftUI

struct KanbanView: View {
    let tasks: [Task]
    let onTaskTap: (Task) -> Void

    @Environment(\.colorScheme) var colorScheme

    private var pendingTasks: [Task] {
        tasks.filter { $0.status == .pending }
    }

    private var inProgressTasks: [Task] {
        tasks.filter { $0.status == .inProgress }
    }

    private var completedTasks: [Task] {
        tasks.filter { $0.status == .completed }
    }

    private var bgDeep: Color {
        colorScheme == .dark ? Theme.darkBgDeep : Theme.lightBgDeep
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            KanbanColumn(
                title: "Pending",
                count: pendingTasks.count,
                color: Theme.darkTextSecondary,
                tasks: pendingTasks,
                onTaskTap: onTaskTap
            )

            KanbanColumn(
                title: "In Progress",
                count: inProgressTasks.count,
                color: Theme.accent,
                tasks: inProgressTasks,
                onTaskTap: onTaskTap
            )

            KanbanColumn(
                title: "Completed",
                count: completedTasks.count,
                color: Theme.success,
                tasks: completedTasks,
                onTaskTap: onTaskTap
            )
        }
        .padding()
        .background(bgDeep)
    }
}

struct KanbanColumn: View {
    let title: String
    let count: Int
    let color: Color
    let tasks: [Task]
    let onTaskTap: (Task) -> Void

    @Environment(\.colorScheme) var colorScheme

    private var textPrimary: Color {
        colorScheme == .dark ? Theme.darkTextPrimary : Theme.lightTextPrimary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(textPrimary)

                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(color)
                    .cornerRadius(10)
            }

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(tasks) { task in
                        TaskCardView(task: task) {
                            onTaskTap(task)
                        }
                    }
                }
            }
        }
        .frame(minWidth: 110, maxWidth: .infinity)
    }
}
