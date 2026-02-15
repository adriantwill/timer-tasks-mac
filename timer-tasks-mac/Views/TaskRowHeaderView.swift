import SwiftData
import SwiftUI

struct TaskRowHeaderView: View {
    let task: TimerTask
    let taskCount: Int
    let timerManager: TimerManager
    let onToggleTimer: (TimerTask) -> Void
    let onAddAppTrigger: (TimerTask) -> Void
    let onAddWindowTrigger: (TimerTask) -> Void
    let onDeleteTask: (TimerTask) -> Void
    let onChangePriority: (TimerTask, Int) -> Void

    var body: some View {
        HStack {
            Circle().fill(
                Color(
                    red: task.category?.color[0] ?? 0.5,
                    green: task.category?.color[1] ?? 0.5,
                    blue: task.category?.color[2] ?? 0.5
                )
            ).fixedSize()
            Text(task.title)
            Picker(
                "Priority",
                selection: Binding(
                    get: { task.priority + 1 },
                    set: { onChangePriority(task, $0 - 1) }
                )
            ) {
                ForEach(1...max(1, taskCount), id: \.self) { value in
                    Text("\(value)")
                }
            }
            .labelsHidden()
            .frame(width: 60)
            Button {
                onToggleTimer(task)
            } label: {
                Image(
                    systemName: timerManager.activeTask == task
                        ? "pause.circle" : "play.circle"
                )
            }
            .buttonStyle(.plain)
            Text(
                Duration.seconds(task.elapsedTime).formatted(
                    .time(pattern: .hourMinuteSecond)
                )
            )
            .monospacedDigit()
            Button(
                "",
                systemImage: "app",
                action: { onAddAppTrigger(task) }
            )
            Button("", systemImage: "plus.app") {
                onAddWindowTrigger(task)
            }
            Button(
                "",
                systemImage: "trash",
                action: { onDeleteTask(task) }
            )
            .buttonStyle(.plain)
        }
    }
}
