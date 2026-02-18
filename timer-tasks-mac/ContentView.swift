//
//  ContentView.swift
//  timer-tasks-mac
//
//  Created by Adrian Will on 2/1/26.
//

import AppKit
import SwiftData
import SwiftUI
internal import UniformTypeIdentifiers

struct ContentView: View {

    @Environment(\.modelContext) var modelContext
    @Environment(\.scenePhase) var scenePhase
    @Query(sort: \TimerTask.priority) var tasks: [TimerTask]
    @State var taskTitle = "New Task"
    @State var categoryTitle = "New Category"
    @State var timerManager = TimerManager.shared
    @State private var expandedTaskId: UUID? = nil
    @State private var showWindowPicker = false
    @State private var windowTitles: [String] = []
    @State private var pendingBundleId: String?
    @State private var pendingTask: TimerTask?
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var color: Color = .red
    @State private var selectedCategory: Category?
    @State private var editingTriggerId: UUID? = nil
    @State private var editedTitle = ""
    @Query var categories: [Category]
    var body: some View {
        VStack {
            TaskListView(
                tasks: tasks,
                expandedTaskId: $expandedTaskId,
                editingTriggerId: $editingTriggerId,
                editedTitle: $editedTitle,
                timerManager: timerManager,
                onToggleTimer: toggleTimer,
                onAddAppTrigger: addAppTrigger,
                onAddWindowTrigger: addWindowTrigger,
                onDeleteTask: { modelContext.delete($0) },
                onDeleteTrigger: { modelContext.delete($0) },
                onChangePriority: changePriority
            )
            AddTaskSectionView(
                taskTitle: $taskTitle,
                selectedCategory: $selectedCategory,
                categories: categories,
                isAddDisabled: !isValidTaskTitle(taskTitle),
                onAddTask: addTask
            )
            AddCategorySectionView(
                categoryTitle: $categoryTitle,
                color: $color,
                onAddCategory: addCategory
            )
        }
        .padding()
        .onAppear {
            AppMonitor.shared.configure(modelContext: modelContext)
            if !AppMonitor.shared.checkAccessibilityPermission() {
                errorMessage = "Accessibility permission is required for automatic tracking."
                showError = true
            }
            AppMonitor.shared.startMonitoring()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background || newPhase == .inactive {
                do {
                    try modelContext.save()
                } catch {
                    errorMessage = "Save failed on scene change: \(error.localizedDescription)"
                    showError = true
                    print("Save failed on scene change: \(error)")
                }
            }
        }
        .confirmationDialog(
            "Select Window",
            isPresented: $showWindowPicker,
            titleVisibility: .visible
        ) {
            ForEach(windowTitles, id: \.self) { title in
                Button(title) {
                    if let pendingTask = pendingTask, let pendingBundleId = pendingBundleId {
                        let trigger = TaskTrigger(
                            bundleId: pendingBundleId,
                            task: pendingTask,
                            title: title
                        )
                        pendingTask.triggers.append(trigger)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
    }
    
    private func toggleTimer(for task: TimerTask) {
        if timerManager.activeTask == task {
            timerManager.stop()
        } else {
            timerManager.start(task: task)
        }
    }
    
    private func addAppTrigger(to task: TimerTask) {
        let panel = NSOpenPanel()
        panel.directoryURL = URL(
            fileURLWithPath: "/Applications",
            isDirectory: true
        )
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        if panel.runModal() == .OK {
            if let url = panel.url {
                if let bundle = Bundle(url: url),
                    let id = bundle.bundleIdentifier
                {
                    print("Selected App ID: \(id)")
                    task.triggers
                        .append(
                            TaskTrigger(
                                bundleId: id,
                                task: task
                            )
                        )
                }
            }
        }
    }
    
    private func addWindowTrigger(to task: TimerTask) {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        if !AXIsProcessTrustedWithOptions(options) {
            errorMessage = "Accessibility permission is required to detect window titles. Please grant permission in System Settings."
            showError = true
            return
        }
        
        let panel = NSOpenPanel()
        panel.directoryURL = URL(
            fileURLWithPath: "/Applications",
            isDirectory: true
        )
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        if panel.runModal() == .OK {
            if let url = panel.url {
                if let bundle = Bundle(url: url),
                   let bid = bundle.bundleIdentifier {
                    print("Selected bundle ID: \(bid)")
                    let runningApps = NSWorkspace.shared.runningApplications
                    if let app = runningApps.first(where: { $0.bundleIdentifier == bid}) {
                        let pid = app.processIdentifier
                        let appElement = AXUIElementCreateApplication(pid)
                        var windows: AnyObject?
                        
                        AXUIElementCopyAttributeValue(
                            appElement,
                            kAXWindowsAttribute as CFString,
                            &windows
                        )
                        
                        pendingBundleId = bid
                        pendingTask = task
                        windowTitles.removeAll()
                        
                        if let windowArray = windows as? [AXUIElement] {
                            for window in windowArray {
                                var title: AnyObject?
                                AXUIElementCopyAttributeValue(
                                    window,
                                    kAXTitleAttribute as CFString,
                                    &title
                                )
                                if let windowTitle = title as? String {
                                    windowTitles.append(windowTitle)
                                }
                            }
                        }
                        
                        showWindowPicker = true
                        print("Found \(windowTitles.count) windows, showing picker")
                    } else {
                        print("App not running: \(bid)")
                    }
                }
            }
        }
    }
    private func addCategory() {
        let nsColor = NSColor(color).usingColorSpace(.sRGB)!
        let newCategory = Category(name: categoryTitle, color: [
            Double(nsColor.redComponent),
            Double(nsColor.greenComponent),
            Double(nsColor.blueComponent)
        ])
        modelContext.insert(newCategory)
        categoryTitle = ""
        color = Color.black
    }

    private func isValidTaskTitle(_ title: String) -> Bool {
        return title.trimmingCharacters(in: .whitespacesAndNewlines).count > 0
    }

    private func addTask() {
        let trimmedTitle = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        // Use selected category or default/uncategorized
        let category = selectedCategory ?? getOrCreateDefaultCategory()
        let nextPriority = (tasks.map { $0.priority }.max() ?? -1) + 1

        let new_task = TimerTask(
            title: trimmedTitle,
            priority: nextPriority,
            category: category

        )
        modelContext.insert(new_task)
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Save failed after add task: \(error.localizedDescription)"
            showError = true
            print("Save failed after add task: \(error)")
        }
        taskTitle = ""
    }

    private func getOrCreateDefaultCategory() -> Category {
        // Look for existing "Uncategorized" category
        if let defaultCat = categories.first(where: { $0.name == "Uncategorized" }) {
            return defaultCat
        }

        // Create default category
        let defaultCategory = Category(
            name: "Uncategorized",
            color: [0.5, 0.5, 0.5] // Gray
        )
        modelContext.insert(defaultCategory)
        return defaultCategory
    }

    private func changePriority(for task: TimerTask, to newPriority: Int) {
        guard tasks.count > 1 else {
            task.priority = 0
            return
        }
        let clamped = min(max(newPriority, 0), tasks.count - 1)
        var reordered = tasks.sorted { $0.priority < $1.priority }
        if let index = reordered.firstIndex(where: { $0.id == task.id }) {
            let item = reordered.remove(at: index)
            reordered.insert(item, at: clamped)
            for (idx, item) in reordered.enumerated() {
                item.priority = idx
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: TimerTask.self,
        TaskTrigger.self,
        Category.self,
        configurations: config
    )

    let category = Category(name: "Work", color: [0.16, 0.43, 0.94])
    let task = TimerTask(title: "Design App", category: category)
    task.elapsedTime = 5400

    let trigger = TaskTrigger(
        bundleId: "com.microsoft.VSCode",
        task: task
    )
    task.triggers.append(trigger)

    container.mainContext.insert(category)
    container.mainContext.insert(task)

    return ContentView()
        .modelContainer(container)
}
