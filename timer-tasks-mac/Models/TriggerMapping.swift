//
//  TriggerMapping.swift
//  timer-tasks-mac
//
//  Created by Adrian Will on 2/1/26.
//

import SwiftData
import Foundation

@Model
class TriggerMapping {
    var pattern: String
    var patternType: PatternType
    var taskTitle: String
    init(pattern: String, patternType: PatternType, taskTitle: String) {
        self.pattern = pattern
        self.patternType = patternType
        self.taskTitle = taskTitle
    }
}

enum PatternType: String, Codable {
    case app, title, url
}
