import NIOSSL
import Fluent
import FluentPostgresDriver
import Leaf
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    if let databaseURL = Environment.get("DATABASE_URL") {
        print("databaseURL: \(databaseURL)")
        var psqlConfig = try SQLPostgresConfiguration(url: databaseURL)
        //Esto es para poder trabajar en local ya que no tenemos activado el SSL
        psqlConfig.coreConfiguration.tls = .disable
        app.databases.use(.postgres(configuration: psqlConfig), as: .psql)
    }

    app.migrations.add(CreateUsers())
    app.migrations.add(CreateProjects())
    
    app.views.use(.leaf)

    // register routes
    try routes(app)
}
