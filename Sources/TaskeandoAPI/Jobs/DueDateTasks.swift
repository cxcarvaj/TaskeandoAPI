//
//  DueDateTasks.swift
//  TaskeandoAPI
//
//  Created by Carlos Xavier Carvajal Villegas on 3/6/25.
//

import Vapor
import Fluent
import Queues
import APNSCore
import APNS
import VaporAPNS

struct Payload: Codable {
    let projectID: String
    let taskID: String
}

struct DueDateTasks: AsyncScheduledJob {
    func run(context: QueueContext) async throws {
        let db = context.application.db
        let now = Date()
        let oneMinuteAgo = now.addingTimeInterval(-60)
        let queryTask = try await Tasks.query(on: db)
            .group(.and) { query in
                query.filter(\.$dateDeadline >= oneMinuteAgo)
                     .filter(\.$dateDeadline <= now)
            }
            .with(\.$user) { user in
                user.with(\.$deviceTokens)
            }
            .with(\.$project)
            .all()
        
        for task in queryTask {
            try await sendNotification(context: context, task: task, tokens: task.user.deviceTokens)
        }
    }
    
    func sendNotification(context: QueueContext, task: Tasks, tokens: [UserDeviceTokens]) async throws {
        let payload = try Payload(projectID: task.project.requireID().uuidString,
                                  taskID: task.requireID().uuidString)
        for token in tokens {
            let content = APNSAlertNotificationContent(title: .raw("Fecha de tarea expirada"),
                                                       subtitle: .raw("Tarea \(task.name) se ha cumplido en fecha"))
            let alert = APNSAlertNotification(alert: content,
                                              expiration: .immediately,
                                              priority: .immediately,
                                              topic: "com.cxcarvaj.Taskeando",
                                              payload: payload)
            
            try await context.application.apns.client.sendAlertNotification(alert, deviceToken: token.deviceToken)
            print("Enviada notificación")
        }
    }
}
