import SwiftData
import SwiftUI

struct TriggerListView: View {
    let task: TimerTask
    @Binding var editingTriggerId: UUID?
    @Binding var editedTitle: String
    let onDeleteTrigger: (TaskTrigger) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(task.triggers) { trigger in
                HStack {
                    Text(trigger.bundleId)

                    if let title = trigger.title {
                        let isEditing = editingTriggerId == trigger.id
                        if isEditing {
                            TextField("Window title", text: $editedTitle)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            Text(title)
                        }
                        Button(
                            "",
                            systemImage: isEditing
                                ? "tray.and.arrow.down"
                                : "pencil"
                        ) {
                            if isEditing {
                                let trimmed = editedTitle.trimmingCharacters(
                                    in: .whitespacesAndNewlines
                                )
                                trigger.title = trimmed.isEmpty ? nil : trimmed
                                editingTriggerId = nil
                            } else {
                                editedTitle = title
                                editingTriggerId = trigger.id
                            }
                        }
                        Toggle(
                            "Exact",
                            isOn: Binding(
                                get: { trigger.isExactTitleMatch },
                                set: { trigger.isExactTitleMatch = $0 }
                            )
                        )
                        .toggleStyle(.checkbox)
                    }
                    Toggle(
                        "Only continues if timer already running",
                        isOn: Binding(
                            get: { trigger.previousActive },
                            set: { trigger.previousActive = $0 }
                        )
                    )
                    Spacer()
                    Button("", systemImage: "xmark.circle.fill") {
                        onDeleteTrigger(trigger)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.leading, 20)
    }
}
