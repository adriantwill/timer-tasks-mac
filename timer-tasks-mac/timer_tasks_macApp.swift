//
//  timer_tasks_macApp.swift
//  timer-tasks-mac
//
//  Created by Adrian Will on 2/1/26.
//

import SwiftUI
import SwiftData

@main
struct timer_tasks_macApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [TimerTask.self, TaskTrigger.self])
        .environment(TimerManager())
    }
}
