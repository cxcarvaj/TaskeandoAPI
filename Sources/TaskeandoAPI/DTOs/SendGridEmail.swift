//
//  SendGridEmail.swift
//  TaskeandoAPI
//
//  Created by Carlos Xavier Carvajal Villegas on 24/5/25.
//

import Vapor

struct SendGridEmail: Content {
    struct Personalization: Content {
        struct Recipient: Content {
            let email: String
        }
        let to: [Recipient]
    }
    
    struct From: Content {
        let email: String
    }
    
    struct EmailContent: Content {
        let type: String
        let value: String
    }
    
    let personalizations: [Personalization]
    let from: From
    let subject: String
    let content: [EmailContent]
}

struct SendGrid {
    static let shared = SendGrid()
    
    private init() {}
    
    func mensaje(token: String) -> String {
     #"""
    <!DOCTYPE html>
    <html lang="es">
    <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Bienvenido a Taskeando</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f4f4f4;
            color: #333;
            margin: 0;
            padding: 20px;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            background-color: #ffffff;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
        }
        h1 {
            color: #4CAF50;
        }
        p {
            line-height: 1.6;
        }
        .button {
            display: inline-block;
            padding: 10px 20px;
            margin: 20px 0;
            background-color: #4CAF50;
            color: #ffffff;
            text-decoration: none;
            border-radius: 5px;
        }
        .footer {
            margin-top: 20px;
            font-size: 0.9em;
            color: #777;
        }
    </style>
    </head>
    <body>
    <div class="container">
        <h1>¡Bienvenido a Taskeando!</h1>
        <p>Estimado usuario,</p>
        <p>Nos complace darte la bienvenida a Taskeando, tu nuevo aliado en la gestión de tareas. Estamos emocionados de que te unas a nuestra comunidad y esperamos que nuestra plataforma te ayude a alcanzar tus objetivos de manera eficiente y organizada.</p>
        <p>En Taskeando, creemos que una buena organización es clave para el éxito. Por ello, hemos diseñado una herramienta intuitiva y potente que te permitirá gestionar tus tareas y proyectos con facilidad.</p>
        <p>Para empezar, te invitamos a explorar las siguientes funcionalidades:</p>
        <ul>
            <li>Creación y seguimiento de tareas</li>
            <li>Gestión de proyectos</li>
            <li>Colaboración en equipo</li>
            <li>Recordatorios y notificaciones</li>
        </ul>
        <p>Antes de empezar, necesitamos validar tu email. Por favor, dentro del dispositivo donde tengas instalada la aplicación, pulsa en el botón de abajo para abrir la app y validar tu email.</p>
        <a href="https://acoding.academy/validateEmail?token=\#(token)" class="button">Validar Email</a>
        <p>¡Gracias por elegir Taskeando!</p>
        <p>Saludos cordiales,</p>
        <p>El equipo de Taskeando</p>
        <div class="footer">
            <p>© 2025 Taskeando. Todos los derechos reservados.</p>
            <p>Si no deseas recibir más correos electrónicos de nuestra parte, puedes <a href="https://swiftask.example.com/unsubscribe">darte de baja aquí</a>.</p>
        </div>
    </div>
    </body>
    </html>
    """#
    }
    
    func sendEmail(req: Request, to email: String, token: String) async throws {
        let emailMsg = SendGridEmail(personalizations: [
            SendGridEmail.Personalization(
                to: [SendGridEmail.Personalization.Recipient(email: email)])
        ],
                                     from: SendGridEmail.From(email: "cxcarvaj@gmail.com"),
                                     subject: "Bienvenido a Taskeando",
                                     content: [
                                        SendGridEmail.EmailContent(type: "text/html",
                                                                   value: mensaje(token: token))
                                     ])
        
        let response = try await req.client.post("https://api.sendgrid.com/v3/mail/send") { request in
            request.headers.contentType = .json
            request.headers.bearerAuthorization = BearerAuthorization(token: Environment.get("SENDGRID_API_KEY") ?? "")
            try request.content.encode(emailMsg)
        }
        
        if response.status == .accepted {
            req.logger.info("Email enviado a la dirección \(email).")
        } else {
            req.logger.error("Error enviando a la dirección \(email).")
        }
    }
}
