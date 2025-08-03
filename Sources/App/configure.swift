import Vapor
import Fluent
import FluentPostgresDriver
import Redis

public func configure(_ app: Application) throws {
    if let dbURL = Environment.get("DATABASE_URL"), var postgresConfig = PostgresConfiguration(url: dbURL) {
        app.databases.use(.postgres(configuration: postgresConfig), as: .psql)
    } else {
        app.databases.use(.postgres(
            hostname: "db",
            username: "vapor",
            password: "vapor",
            database: "vapor"
        ), as: .psql)
    }

    app.migrations.add(CreateTodo())

    try app.redis.configuration = try RedisConfiguration(hostname: "redis")

    try routes(app)
}
