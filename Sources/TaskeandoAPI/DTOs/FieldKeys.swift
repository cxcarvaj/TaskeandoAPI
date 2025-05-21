//
//  FieldKeys.swift
//  TaskeandoAPI
//
//  Created by Carlos Xavier Carvajal Villegas on 20/5/25.
//


import Vapor
import Fluent

extension FieldKey {
    static let name = FieldKey("name")
    static let project = FieldKey("project")
    static let email = FieldKey("email")
    static let user = FieldKey("user")
}