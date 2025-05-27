//
//  UserJWTAuthenticator.swift
//  TaskeandoAPI
//
//  Created by Carlos Xavier Carvajal Villegas on 27/5/25.
//

import Vapor
import JWT

struct UserJWTAuthenticator: JWTAuthenticator {
    func authenticate(jwt: JSONWebTokenPayload, for request: Request) async throws {
        guard let userID = UUID(uuidString: jwt.sub.value) else { return }
        if let user = try await Users.find(userID, on: request.db) {
            request.auth.login(user)
        }
    }
}
