//
//  UsersController.swift
//  TaskeandoAPI
//
//  Created by Carlos Xavier Carvajal Villegas on 21/5/25.
//

import Vapor
import Fluent
import JWT
import Redis

struct UsersController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api")
        api.post("loginSIWA", use: loginSIWA)
        
        let create = api.grouped(AppAPIKeyMiddleware())
        create.post("createUser", use: createUser)
        create.post("validateUser", use: validateUser)
        
        // Usuario/contraseña tradicional (token propio)
        let secureUserPass = api.grouped(Users.authenticator(), Users.guardMiddleware())
        secureUserPass.get("loginUser", use: loginUser)
        secureUserPass.get("loginUserJWT", use: loginUserJWT)
        
        // Token personalizado (por ejemplo, para refresh con token propio)
        let secureToken = api.grouped(UserTokens.authenticator(), Users.guardMiddleware())
        secureToken.get("testConnection", use: testConnection)
        secureToken.get("refresh", use: refresh)
        
        let secureJWT = api.grouped(
            UserJWTAuthenticator(),     // <-- Carga el usuario desde el JWT
            Users.guardMiddleware(),    // <-- Exige usuario autenticado
            JWTExpiredMiddleware()      // <-- Lógica de expiración/revocación
        )
        secureJWT.get("testConnectionJWT", use: testConnectionJWT)
        secureJWT.get("refreshJWT", use: refreshJWT)
        secureJWT.get("logoutJWT", use: logoutJWT)
    }
    
    func createUser(_ req: Request) async throws -> HTTPStatus {
        try Users.validate(content: req)
        let newUser = try req.content.decode(Users.self)
        newUser.role = .none
        newUser.password = try Bcrypt.hash(newUser.password)
        let token = [UInt8].random(count: 16).base64
        newUser.emailToken = token
        try await SendGrid.shared.sendEmail(req: req, to: newUser.email, token: token)
        try await newUser.create(on: req.db)
        return .created
    }
    
    func validateUser(req: Request) async throws -> HTTPStatus {
        let validation = try req.content.decode(EmailValidation.self)
        if let user = try await Users.query(on: req.db)
            .filter(\.$emailToken, .equal, validation.token)
            .filter(\.$email, .equal, validation.email)
            .first() {
            user.role = .user
            try await user.update(on: req.db)
            return .accepted
        } else {
            throw Abort(.badRequest)
        }
    }
    
    func loginUser(_ req: Request) async throws -> Token {
        let user = try req.auth.require(Users.self)
        guard user.role != .none else { throw Abort(.unauthorized) }
        let token = try user.generateToken()
        try await token.create(on: req.db)
        return Token(token: token.token)
    }
    
    func loginUserJWT(_ req: Request) async throws -> Token {
        let user = try req.auth.require(Users.self)
        guard user.role != .none else { throw Abort(.unauthorized) }
        let payload = try generateJWT(user: user)
        let jwtSign = try await req.jwt.sign(payload)
        return Token(token: jwtSign)
    }
    
    func refresh(_ req: Request) async throws -> Token {
        let user = try req.auth.require(Users.self)
        try await user.$tokens.load(on: req.db)
        for token in user.tokens {
            try await token.delete(on: req.db)
        }
        let token = try user.generateToken()
        try await token.create(on: req.db)
        return Token(token: token.token)
    }
    
    func refreshJWT(_ req: Request) async throws -> Token {
        let user = try req.auth.require(Users.self)
        guard user.role != .none else { throw Abort(.unauthorized) }
        let payload = try await req.jwt.verify(as: JSONWebTokenPayload.self)
        try await invalidateToken(payload, on: req)
        let payloadNew = try generateJWT(user: user)
        let jwtSign = try await req.jwt.sign(payloadNew)
        return Token(token: jwtSign)
    }
    
    func testConnection(_ req: Request) async throws -> String {
        return "HOLA MUNDO"
    }
    
    func testConnectionJWT(_ req: Request) async throws -> String {
        let user = try req.auth.require(Users.self)
        return "HOLA \(user.name)"
    }
        
    func generateJWT(user: Users) throws -> JSONWebTokenPayload {
        guard let fecha = Calendar.current.date(byAdding: .day, value: 2, to: Date()) else {
            throw Abort(.badRequest)
        }
        return try JSONWebTokenPayload(
            sub: SubjectClaim(value: user.requireID().uuidString),
            exp: ExpirationClaim(value: fecha),
            iss: IssuerClaim(value: "TaskeandoAPI"),
            aud: AudienceClaim(value: ["com.cxcarvaj.Taskeando"]),
            jti: JWKIdentifier(string: UUID().uuidString)
        )
    }
    
    func invalidateToken(_ jwt: JSONWebTokenPayload, on req: Request) async throws {
        let ttl = max(0, Int(jwt.exp.value.timeIntervalSinceNow))
        guard ttl > 0 else { return }
        let key = RedisKey(jwt.jti.string)
        try await req.redis.setex(key, toJSON: jwt, expirationInSeconds: ttl)
    }
    
    func loginSIWA(_ req: Request) async throws -> Token {
         let appleIdentityToken = try await req.jwt.apple.verify()
         let siwaRequest = try req.content.decode(SIWARequest.self)
         if let user = try await Users
             .query(on: req.db)
             .filter(\.$email == appleIdentityToken.subject.value)
             .first() {
             let payload = try generateJWT(user: user)
             let jwtSign = try await req.jwt.sign(payload)
             return Token(token: jwtSign)
         } else {
             let newUser = Users(email: appleIdentityToken.subject.value,
                                 password: "",
                                 name: "\(siwaRequest.lastName ?? ""), \(siwaRequest.name ?? "")",
                                 role: .user)
             try await newUser.create(on: req.db)
             let payload = try generateJWT(user: newUser)
             let jwtSign = try await req.jwt.sign(payload)
             return Token(token: jwtSign)
         }
     }
    
    func logoutJWT(_ req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(Users.self)
        guard user.role != .none else { throw Abort(.unauthorized) }
        let payload = try await req.jwt.verify(as: JSONWebTokenPayload.self)
        try await invalidateToken(payload, on: req)
        return .continue
    }
}
