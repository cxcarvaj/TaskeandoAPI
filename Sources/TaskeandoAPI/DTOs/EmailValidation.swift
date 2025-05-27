//
//  EmailValidation.swift
//  TaskeandoAPI
//
//  Created by Carlos Xavier Carvajal Villegas on 26/5/25.
//

import Vapor

struct EmailValidation: Content {
    let email: String
    let token: String
}
