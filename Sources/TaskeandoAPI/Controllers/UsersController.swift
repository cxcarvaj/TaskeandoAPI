//
//  UsersController.swift
//  TaskeandoAPI
//
//  Created by Carlos Xavier Carvajal Villegas on 21/5/25.
//

import Vapor
import Fluent
import JWT

struct UsersController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api")
//        api.post("createUser", use: createUser)
        api.get("testConnectionJWT", use: testConnectionJWT)
        
        let create = api.grouped(AppAPIKeyMiddleware())
        create.post("createUser", use: createUser)
        
        let secureUserPass = api.grouped(Users.authenticator(), Users.guardMiddleware())
        secureUserPass.get("loginUser", use: loginUser)
        secureUserPass.get("loginUserJWT", use: loginUserJWT)
        
        let secureToken = api.grouped(UserTokens.authenticator(), Users.guardMiddleware())
        secureToken.get("testConnection", use: testConnection)
    }
    
    func createUser(_ req: Request) async throws -> HTTPStatus {
        try Users.validate(content: req)
        let newUser = try req.content.decode(Users.self)
        newUser.password = try Bcrypt.hash(newUser.password)
        try await newUser.create(on: req.db)
        return .created
    }
    
    func loginUser(_ req: Request) async throws -> Token {
        let user = try req.auth.require(Users.self)
        let token = try user.generateToken()
        try await token.create(on: req.db)
        return Token(token: token.token)
    }
    
    func loginUserJWT(_ req: Request) async throws -> Token {
        let user = try req.auth.require(Users.self)
        let payload = try generateJWT(user: user)
        let jwtSign = try await req.jwt.sign(payload)
        return Token(token: jwtSign)
    }
    
    func testConnection(_ req: Request) async throws -> String {
        return "HOLA MUNDO"
    }
    
    func testConnectionJWT(_ req: Request) async throws -> String {
        let user = try await validateJWT(req)
        return "HOLA \(user.name)"
    }
    
    func validateJWT(_ req: Request) async throws -> Users {
        let payload = try await req.jwt.verify(as: JSONWebTokenPayload.self)
        if let user = try await Users.find(UUID(uuidString: payload.sub.value), on: req.db) {
            return user
        } else {
            throw Abort(.forbidden)
        }
    }
    
    func generateJWT(user: Users) throws -> JSONWebTokenPayload {
        guard let fecha = Calendar.current.date(byAdding: .day, value: 2, to: Date()) else {
            throw Abort(.badRequest)
        }
        return try JSONWebTokenPayload(sub: SubjectClaim(value: user.requireID().uuidString),
                                       exp: ExpirationClaim(value: fecha),
                                       iss: IssuerClaim(value: "TaskeandoAPI"),
                                       aud: AudienceClaim(value: ["com.cxcarvaj.Taskeando"]))
    }
}
