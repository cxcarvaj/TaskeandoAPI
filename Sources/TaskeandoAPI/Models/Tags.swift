//
//  Tags.swift
//  TaskeandoAPI
//
//  Created by Carlos Xavier Carvajal Villegas on 20/5/25.
//


import Vapor
import Fluent

final class Tags: Model, @unchecked Sendable {
    static let schema = "tags"
    
    @ID(key: .id) var id: UUID?
    @Field(key: .name) var name: String
    @Parent(key: .project) var project: Projects
    
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?
   
    @Siblings(through: TagsTasks.self, from: \.$tag, to: \.$task) var tasks: [Tasks]
    
    init() {}
    
    init(id: UUID? = nil, name: String, project: Projects.IDValue) {
        self.id = id
        self.name = name
        self.$project.id = project
    }
}
