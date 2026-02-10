//
//  Category.swift
//  timer-tasks-mac
//
//  Created by Adrian Will on 2/9/26.
//
import Foundation
import SwiftData

@Model
class Category: Identifiable {
    var id: UUID = UUID()
    var name: String
    var color: [Double]
    @Relationship(deleteRule: .nullify, inverse: \TimerTask.category)
    var tasks: [TimerTask] = []
    
    init(name: String, color: [Double]) {
        self.name = name
        self.color = color
    }
}
