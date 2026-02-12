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
                    timerManager: timerManager,
                    onToggleTimer: onToggleTimer,
                    onAddAppTrigger: onAddAppTrigger,
                    onAddWindowTrigger: onAddWindowTrigger,
                    onDeleteTask: onDeleteTask
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
