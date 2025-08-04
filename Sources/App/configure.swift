import Vapor
import Fluent
import FluentPostgresDriver
import Redis

public func configure(_ app: Application) async throws {
    await DotEnvFile.load(for: Environment.development, fileio: app.fileio, logger: app.logger)
    app.databases.use(DatabaseConfigurationFactory.postgres(configuration: .init(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "pokhachevskiy",
        password: Environment.get("DATABASE_PASSWORD") ?? "",
        database: Environment.get("DATABASE_NAME") ?? "vapordemo",
        tls: .prefer(try .init(configuration: .clientDefault)))
    ), as: .psql)


    app.migrations.add(CreateTodo())
    app.migrations.add(UpdateTodo())
//    let file = FileMiddleware(publicDirectory: "Public")
//    print("📂 Public dir is: \(app.directory.publicDirectory)")
    // order is sufficient
    app.middleware.use(AddVersionHeaderMiddleware())
//    app.middleware.use(file)

    try await app.autoMigrate()

//    try app.redis.configuration = try RedisConfiguration(hostname: "redis")

    try routes(app)
}
