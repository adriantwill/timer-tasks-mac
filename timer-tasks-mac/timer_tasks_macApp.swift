//
//  timer_tasks_macApp.swift
//  timer-tasks-mac
//
//  Created by Adrian Will on 2/1/26.
//

import SwiftUI
import SwiftData

@main
struct timer_tasks_macApp: App {
    private let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TimerTask.self,
            TaskTrigger.self,
            Category.self
        ])

        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let storeURL = appSupport.appendingPathComponent("timer-tasks-mac.store")

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
//
//// Migration plan for schema versioning
//enum MigrationPlan: SchemaMigrationPlan {
//    static var schemas: [VersionedSchema.Type] {
//        [VersionedSchemaV1.self]
//    }
//
//    static var stages: [MigrationStage] {
//        []
//    }
//}
//
//// Version 1 of the schema
//enum VersionedSchemaV1: VersionedSchema {
//    static var versionIdentifier: Schema.Version = .init(1, 0, 0)
//
//    static var models: [any PersistentModel.Type] {
//        [TimerTask.self, TaskTrigger.self, Category.self]
//    }
//}
