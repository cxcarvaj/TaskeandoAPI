//
//  UserTokens.swift
//  TaskeandoAPI
//
//  Created by Carlos Xavier Carvajal Villegas on 20/5/25.
//


import Vapor
import Fluent
import JWT

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
    
    //Metodo que debemos implementar por el protocolo ModelTokenAuthenticatable
    var isValid: Bool {
        guard let createdAt,
              let rango = Calendar.current.date(byAdding: .day, value: 2, to: createdAt) else {
            return false
        }
        return Date() < rango
    }
}

struct JSONWebTokenPayload: JWTPayload {
    var sub: SubjectClaim //El sujeto del JWT
    var exp: ExpirationClaim
    var iss: IssuerClaim //El que lo generó
    var aud: AudienceClaim //Para quien ha sido generado
    var jti: JWKIdentifier
    
    func verify(using algorithm: some JWTAlgorithm) async throws {
        try exp.verifyNotExpired()
        try aud.verifyIntendedAudience(includes: "com.cxcarvaj.Taskeando")
        if iss.value != "TaskeandoAPI" {
            throw JWTError.invalidHeaderField(reason: "El issuer no es correcto")
        }
    }
}
