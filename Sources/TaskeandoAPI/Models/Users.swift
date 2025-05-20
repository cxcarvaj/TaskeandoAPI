//
//  Users.swift
//  TaskeandoAPI
//
//  Created by Carlos Xavier Carvajal Villegas on 19/5/25.
//


import Vapor
import Fluent

final class Users: Model, @unchecked Sendable {
    static let schema = "users"
    
    @ID(key: .id) var id: UUID?
    @Field(key: "email") var email: String
    @Field(key: "password") var password: String
    @Field(key: "name") var name: String
    @Field(key: "avatar") var avatar: String?
    
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?
    
    init() {}
    
    init(id: UUID? = nil, email: String, password: String, name: String, avatar: String? = nil) {
        self.id = id
        self.email = email
        self.password = password
        self.name = name
        self.avatar = avatar
    }
}
