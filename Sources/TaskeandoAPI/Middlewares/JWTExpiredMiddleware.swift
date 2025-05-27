//
//  JWTExpiredMiddleware.swift
//  TaskeandoAPI
//
//  Created by Carlos Xavier Carvajal Villegas on 26/5/25.
//

import Vapor
import Redis
import JWT

final class JWTExpiredMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        let payload = try await request.jwt.verify(as: JSONWebTokenPayload.self)
        if try await isTokenInvalidated(payload, on: request) {
            throw Abort(.unauthorized)
        }
        return try await next.respond(to: request)
    }
    
    func isTokenInvalidated(_ jwt: JSONWebTokenPayload, on req: Request) async throws -> Bool {
        let key = RedisKey(jwt.jti.string)
        return try await req.redis.get(key, asJSON: JSONWebTokenPayload.self) != nil
    }
}
