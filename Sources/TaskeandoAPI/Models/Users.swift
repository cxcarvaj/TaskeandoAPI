//
//  Users.swift
//  TaskeandoAPI
//
//  Created by Carlos Xavier Carvajal Villegas on 19/5/25.
//


import Vapor
import Fluent

enum UserType: String, Codable {
    case admin, user, none
}

final class Users: Model, Content, @unchecked Sendable {
    static let schema = "users"
    
    @ID(key: .id) var id: UUID?
    @Field(key: .email) var email: String
    @Field(key: "password") var password: String
    @Field(key: .name) var name: String
    @Field(key: "avatar") var avatar: String?
    @Field(key: "email_token") var emailToken: String?
    @Enum(key: "role") var role: UserType
    
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?
    
    @Children(for: \.$user) var tasks: [Tasks]
    @Children(for: \.$user) var tokens: [UserTokens]
    
    @Siblings(through: ProjectsUsers.self, from: \.$user, to: \.$project) var projects: [Projects]
    
    init() {}
    
    init(id: UUID? = nil, email: String, password: String, name: String, avatar: String? = nil, role: UserType) {
        self.id = id
        self.email = email
        self.password = password
        self.name = name
        self.avatar = avatar
        self.role = role
    }
}

extension Users: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty)
        validations.add("password", as: String.self, is: .count(8...))
        validations.add("email", as: String.self, is: .email)
    }
}

extension Users: ModelAuthenticatable {
    static var usernameKey: KeyPath<Users, Field<String>> { \.$email }
    static var passwordHashKey: KeyPath<Users, Field<String>> { \.$password }
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
}

extension Users {
    func generateToken() throws -> UserTokens {
        try UserTokens(token: [UInt8].random(count: 32).base64,
                       user: requireID())
    }
    
    struct PublicUser: Content {
        let email: String
        let name: String
        let avatar: String?
    }
    
    var toPublic: PublicUser {
        PublicUser(email: email, name: name, avatar: avatar)
    }
}
