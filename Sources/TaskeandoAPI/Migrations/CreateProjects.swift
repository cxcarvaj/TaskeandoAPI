//
//  CreateProjects.swift
//  TaskeandoAPI
//
//  Created by Carlos Xavier Carvajal Villegas on 19/5/25.
//
import Vapor
import Fluent

struct CreateProjects: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let taskState = try await database.enum("task_state")
            .case("active")
            .case("cancelled")
            .case("completed")
            .case("inactive")
            .case("onHold")
            .case("pending")
            .create()

        let projectType = try await database.enum("project_type")
            .case("design")
            .case("development")
            .case("education")
            .case("event")
            .case("finance")
            .case("management")
            .case("marketing")
            .case("maintenance")
            .case("documentation")
            .case("research")
            .case("support")
            .case("testing")
            .create()

        try await database.schema(Projects.schema)
            .id()
            .field("name", .string, .required)
            .field("summary", .string)
            .field("type", projectType, .required)
            .field("state", taskState, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(Projects.schema).delete()
        try await database.enum("project_type").delete()
        try await database.enum("task_state").delete()
    }
}
