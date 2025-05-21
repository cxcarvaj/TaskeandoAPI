//
//  CreateTags.swift
//  TaskeandoAPI
//
//  Created by Carlos Xavier Carvajal Villegas on 20/5/25.
//


import Vapor
import Fluent

struct CreateTags: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(Tags.schema)
            .id()
            .field(.name, .string, .required)
            .field("project", .uuid, .required, .references(Projects.schema, .id, onDelete: .cascade))
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(Tags.schema)
            .delete()
    }
}