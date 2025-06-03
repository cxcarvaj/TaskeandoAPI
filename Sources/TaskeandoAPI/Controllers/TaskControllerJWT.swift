//
//  TaskControllerJWT.swift
//  TaskeandoAPI
//
//  Created by Carlos Xavier Carvajal Villegas on 30/5/25.
//


import Vapor
import Fluent

struct TaskControllerJWT: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api")
        let secureToken = api.grouped(
            UserJWTAuthenticator(),     // <-- Primero, para cargar el usuario desde JWT
            Users.guardMiddleware(),    // <-- Luego, para requerir usuario autenticado
            JWTExpiredMiddleware()      // <-- Tu middleware custom, opcionalmente al final
        )
        
        secureToken.group("task") { group in
            group.post(use: createTask)
            group.put(":taskID", use: updateTask)
            group.delete(":taskID", use: deleteTask)
        }
        
        let projectAPI = api.grouped(JWTExpiredMiddleware())
        projectAPI.group("projectJWT") { group in
            group.get(":projectID", "tasks", use: getTasksForProject)
        }
    }
    
    func createTask(_ req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(Users.self)
        let taskDTO = try req.content.decode(ProjectTaskDTO.self)
        
        guard let project = try await Projects.find(taskDTO.projectId, on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await userHasAccess(to: project, user: user, db: req.db)
        
        let newTask = try Tasks(id: taskDTO.id,
                                name: taskDTO.name,
                                summary: taskDTO.summary,
                                dateInit: taskDTO.dateInit,
                                dateDeadline: taskDTO.dateDeadline,
                                priority: taskDTO.priority,
                                state: taskDTO.state,
                                daysRepeat: taskDTO.daysRepeat,
                                projectID: project.requireID(),
                                userID: user.requireID())

        try await newTask.create(on: req.db)
        return .accepted
    }
    
    func getTasksForProject(_ req: Request) async throws -> [Tasks.PublicTasks] {
        let user = try req.auth.require(Users.self)
        let projectID = try req.parameters.require("projectID", as: UUID.self)
        
        guard let project = try await Projects.find(projectID, on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await userHasAccess(to: project, user: user, db: req.db)
        
        return try await project.$tasks.query(on: req.db)
            .with(\.$user)
            .all()
            .map(\.toPublic)
    }
    
    func updateTask(_ req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(Users.self)
        let taskID = try req.parameters.require("taskID", as: UUID.self)
        
        guard let task = try await Tasks.find(taskID, on: req.db) else {
            throw Abort(.notFound)
        }
 
        let project = try await task.$project.get(on: req.db)
        
        try await userHasAccess(to: project, user: user, db: req.db)
        
        let updatedTask = try req.content.decode(ProjectTaskDTO.self)
        
        task.name = updatedTask.name
        task.summary = updatedTask.summary
        task.dateInit = updatedTask.dateInit
        task.dateDeadline = updatedTask.dateDeadline
        task.priority = updatedTask.priority
        task.state = updatedTask.state
        task.daysRepeat = updatedTask.daysRepeat

        if let newProjectID = updatedTask.projectId, newProjectID != (try project.requireID()) {
            guard let newProject = try await Projects.find(newProjectID, on: req.db) else {
                throw Abort(.notFound)
            }
            try await userHasAccess(to: newProject, user: user, db: req.db)
            task.$project.id = newProjectID
        }
        
        try await task.update(on: req.db)
        return .accepted
    }
    
    func deleteTask(_ req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(Users.self)
        let taskID = try req.parameters.require("taskID", as: UUID.self)
        guard let task = try await Tasks.find(taskID, on: req.db) else {
            throw Abort(.notFound)
        }
        
        let project = try await task.$project.get(on: req.db)
        
        try await userHasAccess(to: project, user: user, db: req.db)
        
        try await task.delete(on: req.db)
        return .noContent
    }
    
    private func userHasAccess(to project: Projects, user: Users, db: any Database) async throws {
        let hasAccess = try await project.$users.query(on: db)
            .filter(\.$id == user.requireID())
            .first() != nil || user.role == .admin
        guard hasAccess else {
            throw Abort(.forbidden)
        }
    }
}
