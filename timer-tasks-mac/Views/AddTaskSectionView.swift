import SwiftData
import SwiftUI

struct AddTaskSectionView: View {
    @Binding var taskTitle: String
    @Binding var selectedCategory: Category?
    let categories: [Category]
    let isAddDisabled: Bool
    let onAddTask: () -> Void

    var body: some View {
        VStack {
            TextField("Add Text here", text: $taskTitle)
            Picker("Category", selection: $selectedCategory) {
                Text("Select Category").tag(nil as Category?)
                ForEach(categories) { category in
                    Text(category.name)
                        .tag(category as Category?)
                }
            }
            .labelsHidden()
            Button("Add Task") {
                onAddTask()
            }
            .disabled(isAddDisabled)
        }
    }
}
