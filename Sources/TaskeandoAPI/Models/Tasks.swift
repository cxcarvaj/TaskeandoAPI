//
//  Tasks.swift
//  TaskeandoAPI
//
//  Created by Carlos Xavier Carvajal Villegas on 20/5/25.
//


import Vapor
import Fluent

enum TaskPriority: String, Codable {
    case urgent, high, medium, low
}

final class Tasks: Model, Content, @unchecked Sendable {
    static let schema = "tasks"

    @ID(key: .id) var id: UUID?
    @Field(key: "name") var name: String
    @Field(key: "summary") var summary: String
    @Field(key: "date_init") var dateInit: Date
    @Field(key: "date_deadline") var dateDeadline: Date?
    @Enum(key: "priority") var priority: TaskPriority
    @Enum(key: "state") var state: TaskState
    @Field(key: "days_repeat") var daysRepeat: Int
    @Parent(key: "project") var project: Projects
    @Parent(key: "user") var user: Users
    
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    @Siblings(through: TagsTasks.self, from: \.$task, to: \.$tag) var tags: [Tags]
    
    init() { }

    init(id: UUID? = nil, name: String, summary: String, dateInit: Date, dateDeadline: Date?, priority: TaskPriority, state: TaskState, daysRepeat: Int, projectID: Projects.IDValue, userID: Users.IDValue) {
        self.id = id
        self.name = name
        self.summary = summary
        self.dateInit = dateInit
        self.dateDeadline = dateDeadline
        self.priority = priority
        self.state = state
        self.daysRepeat = daysRepeat
        self.$project.id = projectID
        self.$user.id = userID
    }
}

extension Tasks {
    struct PublicTasks: Content {
        let id: UUID?
        let name: String
        let summary: String
        let dateInit: Date
        let dateDeadline: Date?
        let priority: TaskPriority
        let state: TaskState
        let daysRepeat: Int
        let user: Users.PublicUser
    }
    
    var toPublic: PublicTasks {
        PublicTasks(id: id, name: name, summary: summary, dateInit: dateInit, dateDeadline: dateDeadline, priority: priority, state: state, daysRepeat: daysRepeat, user: user.toPublic)
    }
}
