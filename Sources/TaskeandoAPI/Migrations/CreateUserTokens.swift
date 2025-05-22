//
//  CreateUserTokens.swift
//  TaskeandoAPI
//
//  Created by Carlos Xavier Carvajal Villegas on 20/5/25.
//


import Vapor
import Fluent

struct CreateUserTokens: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(UserTokens.schema)
            .id()
            .field("token", .string, .required)
            .field("user", .uuid, .required, .references(Users.schema, .id, onDelete: .cascade))
            .field("created_at", .datetime)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(UserTokens.schema)
            .delete()
    }
}
