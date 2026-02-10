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
    @Query var tasks: [TimerTask]
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
    @Query var categories: [Category]
    var body: some View {
        VStack {
            taskList
            addTaskSection
            addCategorySection
        }
        .padding()
        .onAppear {
            AppMonitor.shared.configure(modelContext: modelContext)
            AppMonitor.shared.startMonitoring()
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
    
    private var taskList: some View {
        List(tasks) { task in
            DisclosureGroup(
                isExpanded: disclosureBinding(for: task)
            ) {
                triggerList(for: task)
            } label: {
                taskRowHeader(task: task)
            }
        }
    }
    
    private func disclosureBinding(for task: TimerTask) -> Binding<Bool> {
        Binding(
            get: { expandedTaskId == task.id },
            set: { expandedTaskId = $0 ? task.id : nil }
        )
    }
    
    private func triggerList(for task: TimerTask) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(task.triggers) { trigger in
                HStack {
                    Text(trigger.bundleId)
                    if let title = trigger.title {
                        Text(title)
                    }
                    Spacer()
                    Button("", systemImage: "xmark.circle.fill") {
                        modelContext.delete(trigger)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.leading, 20)
    }
    
    private func taskRowHeader(task: TimerTask) -> some View {
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
                toggleTimer(for: task)
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
                action: { addAppTrigger(to: task) }
            )
            Button("", systemImage: "plus.app") {
                addWindowTrigger(to: task)
            }
            Button(
                "",
                systemImage: "trash",
                action: { modelContext.delete(task) }
            )
            .buttonStyle(.plain)
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
    private var addCategorySection: some View {
        VStack {
            TextField("Add Text here", text: $categoryTitle)
            ColorPicker("Pick color", selection: $color)
            Button("Add Category") {
                let nsColor = NSColor(color).usingColorSpace(.sRGB)!
                let new_category = Category(name: categoryTitle, color: [
                    Double(nsColor.redComponent),
                    Double(nsColor.greenComponent),
                    Double(nsColor.blueComponent)
                ])
                modelContext.insert(new_category)
                categoryTitle = ""
                color = Color.black
            }
        }
    }


    private var addTaskSection: some View {
        VStack {
            TextField("Add Text here", text: $taskTitle)
            Picker("Category", selection: $selectedCategory) {
                Text("Select Category").tag(nil as Category?) // Placeholder
                ForEach(categories) { category in
                    HStack {
                        Circle()
                            .fill(
                                Color(
                                    red: category.color[0],
                                    green: category.color[1],
                                    blue: category.color[2]
                                )
                            )
                            .frame(width: 10)
                        Text(category.name)


                    }
                    .tag(category as Category?) // Important: Tag must match selection type
                }
            }
            .labelsHidden() // Hides the label if you just want the dropdown
            Button("Add Task") {
                let new_task = TimerTask(
                    title: taskTitle,
                    category: selectedCategory

                )
                modelContext.insert(new_task)
                taskTitle = ""
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TimerTask.self, TaskTrigger.self, Category.self, configurations: config)

    // Add sample data so the list isn't empty
    let task = TimerTask(title: "Design App")
    container.mainContext.insert(task)

    return ContentView()
        .modelContainer(container)
}

