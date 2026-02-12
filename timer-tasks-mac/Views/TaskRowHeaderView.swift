import SwiftData
import SwiftUI

struct TaskRowHeaderView: View {
    let task: TimerTask
    let timerManager: TimerManager
    let onToggleTimer: (TimerTask) -> Void
    let onAddAppTrigger: (TimerTask) -> Void
    let onAddWindowTrigger: (TimerTask) -> Void
    let onDeleteTask: (TimerTask) -> Void

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
