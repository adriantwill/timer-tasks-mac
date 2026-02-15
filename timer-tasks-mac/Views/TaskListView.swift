import SwiftData
import SwiftUI

struct TaskListView: View {
    let tasks: [TimerTask]
    @Binding var expandedTaskId: UUID?
    @Binding var editingTriggerId: UUID?
    @Binding var editedTitle: String
    let timerManager: TimerManager
    let onToggleTimer: (TimerTask) -> Void
    let onAddAppTrigger: (TimerTask) -> Void
    let onAddWindowTrigger: (TimerTask) -> Void
    let onDeleteTask: (TimerTask) -> Void
    let onDeleteTrigger: (TaskTrigger) -> Void
    let onChangePriority: (TimerTask, Int) -> Void

    var body: some View {
        List(tasks) { task in
            DisclosureGroup(
                isExpanded: disclosureBinding(for: task)
            ) {
                TriggerListView(
                    task: task,
                    editingTriggerId: $editingTriggerId,
                    editedTitle: $editedTitle,
                    onDeleteTrigger: onDeleteTrigger
                )
            } label: {
                TaskRowHeaderView(
                    task: task,
                    taskCount: tasks.count,
                    timerManager: timerManager,
                    onToggleTimer: onToggleTimer,
                    onAddAppTrigger: onAddAppTrigger,
                    onAddWindowTrigger: onAddWindowTrigger,
                    onDeleteTask: onDeleteTask,
                    onChangePriority: onChangePriority
                )
            }
        }
    }

    private func disclosureBinding(for task: TimerTask) -> Binding<Bool> {
        Binding(
            get: { expandedTaskId == task.id },
            set: { expandedTaskId = $0 ? task.id : nil }
        )
    }
}
