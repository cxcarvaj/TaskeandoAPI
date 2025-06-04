//
//  UserDeviceTokens.swift
//  TaskeandoAPI
//
//  Created by Carlos Xavier Carvajal Villegas on 3/6/25.
//

import Vapor
import Fluent

final class UserDeviceTokens: Model, Content, @unchecked Sendable {
    static let schema = "user_device_tokens"
    
    @ID(key: .id) var id: UUID?
    @Field(key: "device_token") var deviceToken: String
    @Parent(key: "user") var user: Users

    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    
    init() {}
    
    init(id: UUID? = nil, deviceToken: String, user: Users.IDValue) {
        self.id = id
        self.deviceToken = deviceToken
        self.$user.id = user
    }
}
