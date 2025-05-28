//
//  SIWARequest.swift
//  TaskeandoAPI
//
//  Created by Carlos Xavier Carvajal Villegas on 27/5/25.
//

import Vapor

struct SIWARequest: Content {
    let name: String?
    let lastName: String?
}
