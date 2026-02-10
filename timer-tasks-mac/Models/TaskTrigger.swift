//
//  TaskTrigger.swift
//  timer-tasks-mac
//
//  Created by Adrian Will on 2/7/26.
//
import SwiftData
import Foundation

@Model
class TaskTrigger: Identifiable {
    var id: UUID = UUID()
    var bundleId: String
    var task: TimerTask
    var title: String?
    init(
        bundleId: String,
        task: TimerTask,
        title: String? = nil,
        id: UUID = UUID()
    ) {
        self.bundleId = bundleId
        self.task = task
        self.title = title
    }
}
