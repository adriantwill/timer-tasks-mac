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
    var isExactTitleMatch: Bool = false
    var previousActive: Bool = false
    init(
        bundleId: String,
        task: TimerTask,
        title: String? = nil,
        isExactTitleMatch: Bool = false,
        id: UUID = UUID()
    ) {
        self.bundleId = bundleId
        self.task = task
        self.title = title
        self.isExactTitleMatch = isExactTitleMatch
    }
}
