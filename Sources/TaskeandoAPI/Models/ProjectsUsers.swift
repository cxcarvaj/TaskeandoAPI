//
//  ProjectsUsers.swift
//  TaskeandoAPI
//
//  Created by Carlos Xavier Carvajal Villegas on 20/5/25.
//



import Vapor
import Fluent

final class ProjectsUsers: Model, @unchecked Sendable {
    static let schema = "projects_users"
    
    @ID(key: .id) var id: UUID?
    @Parent(key: "project") var project: Projects
    @Parent(key: "user") var user: Users
    
    init() {}
    
    init(id: UUID? = nil, project: Projects.IDValue, user: Users.IDValue) {
        self.id = id
        self.$project.id = project
        self.$user.id = user
    }
}
