//
//  CreateDeviceUserTokens.swift
//  TaskeandoAPI
//
//  Created by Carlos Xavier Carvajal Villegas on 3/6/25.
//

import Vapor
import Fluent

struct CreateDeviceUserTokens: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(UserDeviceTokens.schema)
            .id()
            .field("device_token", .string, .required)
            .field("user", .uuid, .required, .references(Users.schema, .id, onDelete: .cascade))
            .field("created_at", .datetime)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(UserDeviceTokens.schema)
            .delete()
    }
}
