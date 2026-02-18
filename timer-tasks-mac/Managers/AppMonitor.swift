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
    private init() {}
    var modelContext: ModelContext?
    var lastKnownTitle = ""
    var lastKnownApp = ""
    var pollingTimer: Timer?
    private var isMonitoring = false

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func checkAccessibilityPermission() -> Bool {
        let options =
            [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    func getWindowTitle(app: NSRunningApplication) -> String? {
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        var focusedWindow: AnyObject?
        let result = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedWindowAttribute as CFString,
            &focusedWindow
        )
        if result == .success {
            var title: AnyObject?
            let result2 = AXUIElementCopyAttributeValue(
                focusedWindow as! AXUIElement,
                kAXTitleAttribute as CFString,
                &title
            )
            if result2 == .success {
                return title as? String
            }
        }
        return nil
    }

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDidActivate),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        self.pollingTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0,
            repeats: true
        ) { _ in
            // Your polling logic here (e.g., API call)

            guard let app = NSWorkspace.shared.frontmostApplication,
                let bundleId = app.bundleIdentifier
            else { return }
            let windowTitle = self.getWindowTitle(app: app)
            if windowTitle != self.lastKnownTitle
                || self.lastKnownApp != bundleId
            {
                self.appDidActivate(
                    nil
                )
            }

        }
    }
    @objc func appDidActivate(_ notification: Notification?) {
        guard let app = NSWorkspace.shared.frontmostApplication,
            let bundleId = app.bundleIdentifier,
            let context = modelContext
        else { return }
        let windowTitle = getWindowTitle(app: app)
        let descriptor = FetchDescriptor<TimerTask>(
            sortBy: [SortDescriptor(\TimerTask.priority, order: .forward)]
        )
        guard let tasks = try? context.fetch(descriptor) else { return }

        let active = TimerManager.shared.activeTask
        let match = tasks.first { task in
            task.triggers.contains { (trigger: TaskTrigger) in
                let isPreviousActiveOk = !trigger.previousActive || active?.id == task.id
                if trigger.title == nil {
                    return trigger.bundleId == bundleId && isPreviousActiveOk
                } else if trigger.bundleId==bundleId{
                    guard let currentTitle = windowTitle,
                        let triggerTitle = trigger.title
                    else { return false }
                    if trigger.isExactTitleMatch {
                        return isPreviousActiveOk && currentTitle
                            .localizedCaseInsensitiveCompare(
                            triggerTitle
                        ) == .orderedSame
                    }
                    return isPreviousActiveOk && currentTitle
                        .localizedCaseInsensitiveContains(
                        triggerTitle
                    )
                }
                return false
            }
        }

        if let match {
            if TimerManager.shared.activeTask?.id != match.id {
                TimerManager.shared.start(task: match)
            }
        } else {
            TimerManager.shared.stop()
        }
        self.lastKnownTitle = windowTitle ?? ""
        self.lastKnownApp = bundleId
    }
}
