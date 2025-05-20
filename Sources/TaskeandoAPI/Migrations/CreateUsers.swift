//
//  CreateUsers.swift
//  TaskeandoAPI
//
//  Created by Carlos Xavier Carvajal Villegas on 19/5/25.
//

import Vapor
import Fluent

struct CreateUsers: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(Users.schema)
            .id()
            .field("email", .string, .required)
            .field("password", .string, .required)
            .field("name", .string, .required)
            .field("avatar", .string)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "email")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("users")
            .delete()
    }
}
