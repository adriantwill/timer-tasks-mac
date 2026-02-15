//
//  Task.swift
//  timer-tasks-mac
//
//  Created by Adrian Will on 2/1/26.
//

import Foundation
import SwiftData
import SwiftUI

@Model
class TimerTask {
    var id: UUID = UUID()
    var title: String
    var priority: Int = 0
    var targetTime: TimeInterval?  // nil = no limit
    var elapsedTime: TimeInterval
    var isManualComplete: Bool
    var category: Category?
    var createdAt: Date = Date()
    var updatedAt: Date?
    @Relationship(deleteRule: .cascade, inverse: \TaskTrigger.task)
    var triggers: [TaskTrigger] = []
    init(
        title: String,
        priority: Int = 0,
        targetTime: TimeInterval? = nil,
        triggers: [TaskTrigger] = [],
        category: Category? = nil
    ) {
        self.title = title
        self.priority = priority
        self.targetTime = targetTime
        self.elapsedTime = 0
        self.isManualComplete = false
        self.triggers = triggers
        self.category = category
    }
}
