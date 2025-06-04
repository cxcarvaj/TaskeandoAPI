//
//  CreateTasks.swift
//  TaskeandoAPI
//
//  Created by Carlos Xavier Carvajal Villegas on 20/5/25.
//


import Vapor
import Fluent

struct CreateTasks: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let priority = try await database.enum("task_priority")
            .case("urgent")
            .case("high")
            .case("medium")
            .case("low")
            .create()
        
        try await database.schema(Tasks.schema)
            .id()
            .field(.name, .string, .required)
            .field("summary", .string, .required)
            .field("date_init", .datetime, .required)
            .field("date_deadline", .datetime)
            .field("priority", priority, .required)
            .field("state", .string, .required)
            .field("days_repeat", .int, .required)
            .field("project", .uuid, .required, .references(Projects.schema, .id, onDelete: .cascade))
            .field("user", .uuid, .required, .references(Users.schema, .id, onDelete: .cascade))
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(Tasks.schema)
            .delete()
        try await database.enum("task_priority")
            .delete()
    }
}
