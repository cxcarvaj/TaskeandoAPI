//
//  ProjectController.swift
//  TaskeandoAPI
//
//  Created by Carlos Xavier Carvajal Villegas on 22/5/25.
//


import Vapor
import Fluent

struct ProjectController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api")
        // Funcionan siempre y cuando usemos OAUTH_TOKEN
        let secureToken = api.grouped(UserTokens.authenticator(), Users.guardMiddleware())
        secureToken.group("project") { group in
            group.post(use: createProject)
            group.get(use: getProjects)
            group.get(":projectID", use: getProject)
            group.get("allProjects", use: getProjectsAdmin)
            group.get(":projectID", "admin", use: getProjectsAdmin)
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
    
    func getProjects(req: Request) async throws -> [Projects.PublicProjects] {
        let user = try req.auth.require(Users.self)
        return try await user.$projects
            .query(on: req.db)
            .with(\.$tags)
            .with(\.$tasks)
            .with(\.$users)
            .all()
            .map(\.toPublic)
    }
    
    func getProject(req: Request) async throws -> Projects.PublicProjects {
        let user = try req.auth.require(Users.self)
        let id = try req.parameters.require("projectID", as: UUID.self)
        if let project = try await user.$projects
            .query(on: req.db)
            .filter(\.$id == id)
            .with(\.$tags)
            .with(\.$tasks)
            .with(\.$users)
            .first() {
            return project.toPublic
        } else {
            throw Abort(.notFound)
        }
    }
    
    func getProjectAdmin(req: Request) async throws -> Projects.PublicProjects {
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
                return project.toPublic
            } else {
                throw Abort(.notFound)
            }
        } else {
            throw Abort(.forbidden)
        }
    }
    
    func getProjectsAdmin(req: Request) async throws -> [Projects.PublicProjects] {
        let user = try req.auth.require(Users.self)
        if user.role == .admin {
            return try await Projects
                .query(on: req.db)
                .with(\.$tags)
                .with(\.$tasks)
                .with(\.$users)
                .all()
                .map(\.toPublic)
        } else {
            throw Abort(.forbidden)
        }
    }
}
