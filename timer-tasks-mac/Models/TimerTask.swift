//
//  Task.swift
//  timer-tasks-mac
//
//  Created by Adrian Will on 2/1/26.
//

import SwiftData
import Foundation
import SwiftUI

@Model
class TimerTask {
    var id: UUID = UUID() 
    var title: String
    var targetTime: TimeInterval?  // nil = no limit
    var elapsedTime: TimeInterval
    var color: [Double]  // expects three elements representing the color components
    var isManualComplete: Bool
    @Relationship(deleteRule: .cascade, inverse: \TaskTrigger.task)
    var triggers: [TaskTrigger] = []
    init(title: String, targetTime: TimeInterval? = nil, color: [Double], triggers: [TaskTrigger] = []) {
        self.title = title
        self.targetTime = targetTime
        self.elapsedTime = 0
        self.color = color
        self.isManualComplete = false
        self.triggers = triggers
    }
}

