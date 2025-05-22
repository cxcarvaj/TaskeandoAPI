//
//  AppAPIKeyMiddleware.swift
//  TaskeandoAPI
//
//  Created by Carlos Xavier Carvajal Villegas on 21/5/25.
//


import Vapor

final class AppAPIKeyMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        guard let header = request.headers["X-API-Key"].first,
              header == "sLGH38NhEJ0_anlIWwhsz1-LarClEohiAHQqayF0FY" else {
            throw Abort(.unauthorized)
        }
        return try await next.respond(to: request)
    }
}
