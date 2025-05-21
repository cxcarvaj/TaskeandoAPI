//
//  CreateTagsTasks.swift
//  TaskeandoAPI
//
//  Created by Carlos Xavier Carvajal Villegas on 20/5/25.
//


import Vapor
import Fluent

struct CreateTagsTasks: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(TagsTasks.schema)
            .id()
            .field("task", .uuid, .references(Tasks.schema, .id, onDelete: .cascade))
            .field("tag", .uuid, .references(Tags.schema, .id, onDelete: .cascade))
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(TagsTasks.schema)
            .delete()
    }
}