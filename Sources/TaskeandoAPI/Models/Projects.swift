//
//  Projects.swift
//  TaskeandoAPI
//
//  Created by Carlos Xavier Carvajal Villegas on 19/5/25.
//

import Vapor
import Fluent

enum TaskState: String, Codable {
    case active
    case cancelled
    case completed
    case inactive
    case onHold
    case pending
}

enum ProjectType: String, Codable {
    case design
    case development
    case education
    case event
    case finance
    case management
    case marketing
    case maintenance
    case documentation
    case research
    case support
    case testing
}

final class Projects: Model, Content, @unchecked Sendable {
    static let schema = "projects"
    
    @ID(key: .id) var id: UUID?
    @Field(key: "name") var name: String
    @Field(key: "summary") var summary: String?
    @Enum(key: "type") var type: ProjectType
    @Enum(key: "state") var state: TaskState
    
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?
    
    @Children(for: \.$project) var tasks: [Tasks]
    @Children(for: \.$project) var tags: [Tags]
    
    @Siblings(through: ProjectsUsers.self, from: \.$project, to: \.$user) var users: [Users]
    
    init() {}
    
    init(id: UUID? = nil, name: String, summary: String? = nil, type: ProjectType, state: TaskState) {
        self.id = id
        self.name = name
        self.summary = summary
        self.type = type
        self.state = state
    }
}
