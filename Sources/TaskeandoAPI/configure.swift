import NIOSSL
import Fluent
import FluentPostgresDriver
import Leaf
import Vapor
import JWT
import Redis
import APNS
import VaporAPNS
import APNSCore
import Queues
import QueuesRedisDriver

// configures your application
public func configure(_ app: Application) async throws {
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

//    if let databaseURL = Environment.get("DATABASE_URL") {
//        print("databaseURL: \(databaseURL)")
//        var psqlConfig = try SQLPostgresConfiguration(url: databaseURL)
//        //Esto es para poder trabajar en local ya que no tenemos activado el SSL
//        psqlConfig.coreConfiguration.tls = .disable
//        app.databases.use(.postgres(configuration: psqlConfig), as: .psql)
//    }
    guard let hostname = Environment.get("DB_HOST"),
          let portString = Environment.get("DB_PORT"),
          let username = Environment.get("DB_USERNAME"),
          let password = Environment.get("DB_PASSWORD"),
          let database = Environment.get("DB_DATABASE"),
          let port = Int(portString) else {
        fatalError("⛔️ Error crítico: No se pudieron obtener todas las variables de entorno necesarias para PostgreSQL. Asegúrate de configurar DB_HOST, DB_PORT, DB_USERNAME, DB_PASSWORD y DB_DATABASE en tu archivo .env")
    }
    let psqlConfig = SQLPostgresConfiguration(
        hostname: hostname,
        port: port,
        username: username,
        password: password,
        database: database,
        tls: .disable
    )
    
    app.databases.use(.postgres(configuration: psqlConfig), as: .psql)
    print("💾 PostgreSQL configurado correctamente con host: \(hostname), base de datos: \(database)")
    
    app.migrations.add(CreateUsers())
    app.migrations.add(CreateProjects())
    app.migrations.add(CreateTags())
    app.migrations.add(CreateTasks())
    app.migrations.add(CreateProjectsUsers())
    app.migrations.add(CreateTagsTasks())
    app.migrations.add(CreateUserTokens())
    app.migrations.add(CreateDeviceUserTokens())
    
    app.views.use(.leaf)
    
    //El hmac es mi secret que forma parte del JWT
    await app.jwt.keys.add(hmac: "jobsSteve", digestAlgorithm: .sha256)
    
    let redisConfiguration = try RedisConfiguration(hostname: "localhost")
    app.redis.configuration = redisConfiguration
    app.queues.use(.redis(redisConfiguration))
    
    app.queues.schedule(DueDateTasks())
        .minutely()
        .at(0)
    
    try app.queues.startScheduledJobs()
    
    app.jwt.apple.applicationIdentifier = "com.cxcarvaj.Taskeando"
    
    let keyURL = URL(fileURLWithPath: app.directory.workingDirectory).appending(path: "AuthKey_7RZ3DGVM8V.p8")
    let keyData = try Data(contentsOf: keyURL)
    if let keyAPNSContent = String(data: keyData, encoding: .utf8) {
        let apnsConfig = try APNSClientConfiguration(authenticationMethod: .jwt(privateKey: .loadFrom(string: keyAPNSContent),
                                                                                keyIdentifier: "7RZ3DGVM8V",
                                                                                teamIdentifier: "ZS8A7XMWJ4"),
                                                     environment: .development)
        app.apns.containers.use(apnsConfig,
                                eventLoopGroupProvider: .shared(app.eventLoopGroup),
                                responseDecoder: JSONDecoder(),
                                requestEncoder: JSONEncoder(),
                                as: .development)
    }
    
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    
    ContentConfiguration.global.use(decoder: decoder, for: .json)
    
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.keyEncodingStrategy = .convertToSnakeCase
    
    ContentConfiguration.global.use(encoder: encoder, for: .json)

    // register routes
    try routes(app)
}
