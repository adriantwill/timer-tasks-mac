//
//  AppMonitor.swift
//  timer-tasks-mac
//
//  Created by Adrian Will on 2/6/26.
//

import AppKit
import SwiftData

class AppMonitor {
    static let shared = AppMonitor()
    private init () {}
    var modelContext: ModelContext?

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func startMonitoring(){
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDidActivate),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }
    @objc func appDidActivate(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
        print("Switched to app: \(app.localizedName ?? "Unknown") (\(app.bundleIdentifier ?? "No ID"))")
        let bundleId = app.bundleIdentifier, context = modelContext
        let descriptor = FetchDescriptor<TriggerMapping>()
        guard let mappings = try? context?.fetch(descriptor) else { return }
        if let match = mappings.first(where: { mapping in
            mapping.patternType == .app && mapping.pattern == bundleId
        }) {
            print(
                "Found trigger for app: \(String(describing: bundleId)) -> Task: \(match.taskTitle)"
            )

            // 3. Find the Task object
            let taskDescriptor = FetchDescriptor<TimerTask>(
                predicate: #Predicate { $0.title == match.taskTitle }
            )

            if let task = try? context?.fetch(taskDescriptor).first {
                // 4. Start the timer!
                TimerManager.shared.start(task: task)
            }
        }
    }
}
