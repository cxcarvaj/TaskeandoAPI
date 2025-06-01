//
//  ProjectControllerJWT.swift
//  TaskeandoAPI
//
//  Created by Carlos Xavier Carvajal Villegas on 26/5/25.
//


import Vapor
import Fluent

struct ProjectControllerJWT: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api")
        
        let secureToken = api.grouped(
            UserJWTAuthenticator(),     // <-- Primero, para cargar el usuario desde JWT
            Users.guardMiddleware(),    // <-- Luego, para requerir usuario autenticado
            JWTExpiredMiddleware()      // <-- Tu middleware custom, opcionalmente al final
        )
        secureToken.group("projectJWT") { group in
            group.post(use: createProject)
            group.get(use: getProjects)
            group.get(":projectID", use: getProject)
            group.get("allProjects", use: getProjectsAdmin)
            group.get(":projectID", "admin", use: getProjectAdmin)
        }
    }
    
    func createProject(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(Users.self)
        let newProject = try req.content.decode(Projects.self)
        if let project = try await Projects.find(newProject.id, on: req.db) {
            if try await project.$users.query(on: req.db)
                .filter(\.$id == user.requireID())
                .first() != nil || user.role == .admin {
                project.name = newProject.name
                project.summary = newProject.summary
                project.type = newProject.type
                project.state = newProject.state
                try await project.update(on: req.db)
            }
        } else {
            try await newProject.create(on: req.db)
            try await newProject.$users.attach(user, on: req.db)
        }
        return .accepted
    }
    
    func getProjects(req: Request) async throws -> [Projects] {
        let user = try req.auth.require(Users.self)
        return try await user.$projects
            .query(on: req.db)
            .with(\.$tags)
            .with(\.$tasks) {task in
                task.with(\.$user)
            }
            .with(\.$users)
            .all()
    }
    
    func getProject(req: Request) async throws -> Projects {
        let user = try req.auth.require(Users.self)
        let id = try req.parameters.require("projectID", as: UUID.self)
        if let project = try await user.$projects
            .query(on: req.db)
            .filter(\.$id == id)
            .with(\.$tags)
            .with(\.$tasks)
            .with(\.$users)
            .first() {
            return project
        } else {
            throw Abort(.notFound)
        }
    }
    
    func getProjectAdmin(req: Request) async throws -> Projects {
        let user = try req.auth.require(Users.self)
        let id = try req.parameters.require("projectID", as: UUID.self)
        if user.role == .admin {
            if let project = try await Projects
                .query(on: req.db)
                .filter(\.$id == id)
                .with(\.$tags)
                .with(\.$tasks)
                .with(\.$users)
                .first() {
                return project
            } else {
                throw Abort(.notFound)
            }
        } else {
            throw Abort(.forbidden)
        }
    }
    
    func getProjectsAdmin(req: Request) async throws -> [Projects] {
        let user = try req.auth.require(Users.self)
        if user.role == .admin {
            return try await Projects
                .query(on: req.db)
                .with(\.$tags)
                .with(\.$tasks)
                .with(\.$users)
                .all()
        } else {
            throw Abort(.forbidden)
        }
    }
}
