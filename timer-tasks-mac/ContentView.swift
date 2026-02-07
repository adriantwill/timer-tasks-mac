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
    @Query var tasks: [TimerTask]
    @State var color = Color.red
    @State var title = ""
    @State var timerManager = TimerManager.shared
    var body: some View {
        VStack {
            List(tasks) { task in
                HStack{
                    Circle().fill(Color(red: task.color[0], green: task.color[1], blue: task.color[2])).fixedSize()
                    Text(task.title)
                    Button {
                        if (timerManager.activeTask == task){
                            timerManager.stop()
                        } else {
                            timerManager.start(task: task)
                        }
                    } label: {
                        Image(systemName: timerManager.activeTask == task ? "pause.circle" : "play.circle")
                    }

                    Text(Duration.seconds(task.elapsedTime).formatted(.time(pattern: .hourMinuteSecond)))
                        .monospacedDigit()
                    Button("", systemImage: "trash", action: {
                        modelContext.delete(task)
                    })
                }
            }
            TextField("Add Text here", text: $title)
            ColorPicker("Pick color", selection: $color)
            Button("Add Task"){
                let nsColor = NSColor(color).usingColorSpace(.sRGB)!
                let new_task = TimerTask(title: title, color: [nsColor.redComponent, nsColor.greenComponent, nsColor.blueComponent])
                modelContext.insert(new_task)
                title = ""
                color = Color.white
            }
        }
        .padding()
        .task {
            AppMonitor.shared.startMonitoring()
        }
        .onAppear {
            AppMonitor.shared.configure(modelContext: modelContext)
            AppMonitor.shared.startMonitoring()
        }
    }
}



#Preview {
    ContentView()
}
