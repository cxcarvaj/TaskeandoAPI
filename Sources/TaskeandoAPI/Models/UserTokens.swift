//
//  UserTokens.swift
//  TaskeandoAPI
//
//  Created by Carlos Xavier Carvajal Villegas on 20/5/25.
//


import Vapor
import Fluent

final class UserTokens: Model, Content, @unchecked Sendable {
    static let schema = "user_tokens"
    
    @ID(key: .id) var id: UUID?
    @Field(key: "token") var token: String
    @Parent(key: "user") var user: Users

    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    
    init() {}
    
    init(id: UUID? = nil, token: String, user: Users.IDValue) {
        self.id = id
        self.token = token
        self.$user.id = user
    }
}

extension UserTokens: ModelTokenAuthenticatable {
    static var valueKey: KeyPath<UserTokens, Field<String>> { \.$token }
    static var userKey: KeyPath<UserTokens, Parent<Users>> { \.$user }
    
    var isValid: Bool {
        guard let createdAt,
              let rango = Calendar.current.date(byAdding: .day, value: 2, to: createdAt) else {
            return false
        }
        return Date() < rango
    }
}
