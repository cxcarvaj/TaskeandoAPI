import Fluent
import Vapor

func routes(_ app: Application) throws {
    try app.register(collection: UsersController())
    try app.register(collection: ProjectController())
    try app.register(collection: ProjectControllerJWT())
    try app.register(collection: TaskControllerJWT())

    
    // Apple App Site Association
    app.get(".well-known", "apple-app-site-association") { req -> Response in
        let association = """
            {
                "webcredentials": {
                    "apps": [
                        "<MI TEAM ID>.<MI BUNDLE ID>"
                    ]
                }
            }
            """
        var headers = HTTPHeaders()
        headers.add(name: .contentType, value: "application/json")
        headers.add(name: .cacheControl, value: "public, max-age=3600")
        headers.add(name: .contentEncoding, value: "identity")
        
        return Response(status: .ok, headers: headers, body: .init(string: association))
    }
}
