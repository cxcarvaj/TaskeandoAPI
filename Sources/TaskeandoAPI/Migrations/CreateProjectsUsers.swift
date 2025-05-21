//
//  CreateProjectsUsers.swift
//  TaskeandoAPI
//
//  Created by Carlos Xavier Carvajal Villegas on 20/5/25.
//


import Vapor
import Fluent

struct CreateProjectsUsers: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(ProjectsUsers.schema)
            .id()
            .field(.project, .uuid, .references(Projects.schema, .id, onDelete: .cascade))
            .field(.user, .uuid, .references(Users.schema, .id, onDelete: .cascade))
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(ProjectsUsers.schema)
            .delete()
    }
}
