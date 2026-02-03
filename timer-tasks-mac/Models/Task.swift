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
class Task {
    var title: String
    var targetTime: TimeInterval?  // nil = no limit
    var elapsedTime: TimeInterval
    var color: [Double]  // expects three elements representing the color components
    var isManualComplete: Bool
    init(title: String, targetTime: TimeInterval? = nil, color: [Double]) {
        self.title = title
        self.targetTime = targetTime
        self.elapsedTime = 0
        self.color = color
        self.isManualComplete = false
    }
}

