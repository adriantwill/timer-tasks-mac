//
//  ContentView.swift
//  timer-tasks-mac
//
//  Created by Adrian Will on 2/1/26.
//

import SwiftUI
import SwiftData
internal import Combine

struct ContentView: View {

    @Environment(\.modelContext) var modelContext
    @Query var tasks: [Task]
    @State var color = Color.red
    @State var title = ""
    @State var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var activeTask: Task?
    var body: some View {
        List(tasks) { task in
            HStack{
                Circle().fill(Color(red: task.color[0], green: task.color[1], blue: task.color[2])).fixedSize()
                Text(task.title)
                Button {
                    if (activeTask != nil){
                        activeTask = nil
                    } else {
                        activeTask = task
                    }
                } label: {
                    Label("", systemImage: "play.circle")
                }

                Text(String(describing: Duration.seconds(task.elapsedTime)))
                Button("", systemImage: "trash", action: {
                    modelContext.delete(task)
                })
            }
        }
        .onReceive(timer) { _ in
            if let active = activeTask {
                active.elapsedTime += 1
            }
        }
        TextField("Add Text here", text: $title)
        ColorPicker("Pick color", selection: $color)
        Button("Add Task"){
            let nsColor = NSColor(color).usingColorSpace(.sRGB)!
            let new_task = Task(title: title, color: [nsColor.redComponent, nsColor.greenComponent, nsColor.blueComponent])
            modelContext.insert(new_task)
            title = ""
            color = Color.white
        }
        
    }

}


#Preview {
    ContentView()
}
