//
//  TagsTasks.swift
//  TaskeandoAPI
//
//  Created by Carlos Xavier Carvajal Villegas on 20/5/25.
//


import Vapor
import Fluent

final class TagsTasks: Model, @unchecked Sendable {
    static let schema = "tasks_tags"
    
    @ID(key: .id) var id: UUID?
    @Parent(key: "task") var task: Tasks
    @Parent(key: "tag") var tag: Tags
    
    init() {}
    
    init(id: UUID? = nil, task: Tasks.IDValue, tag: Tags.IDValue) {
        self.id = id
        self.$task.id = task
        self.$tag.id = tag
    }
}
