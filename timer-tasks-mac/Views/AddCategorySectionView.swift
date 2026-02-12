import SwiftUI

struct AddCategorySectionView: View {
    @Binding var categoryTitle: String
    @Binding var color: Color
    let onAddCategory: () -> Void

    var body: some View {
        VStack {
            TextField("Add Text here", text: $categoryTitle)
            ColorPicker("Pick color", selection: $color)
            Button("Add Category") {
                onAddCategory()
            }
        }
    }
}
