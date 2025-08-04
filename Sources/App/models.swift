import Vapor
import Fluent
import FluentSQL

struct TodoRawDTO: Content {
    static let schema = "todos"

    var id: UUID?
    var title: String
    var is_done: Bool?

    func toDTO() -> TodoDTO {
        .init(id: id, title: title, isDone: is_done ?? false)
    }
}

struct TodoDTO: Content {
    static let schema = "todos"

    var id: UUID?
    var title: String
    var isDone: Bool?

    init(id: UUID? = nil, title: String, isDone: Bool = false) {
        self.id = id
        self.title = title
        self.isDone = isDone
    }

    func toModel() -> Todo {
        .init(id: id, title: title, isDone: isDone ?? false)
    }
}

final class Todo: Model, @unchecked Sendable {
    static let schema = "todos"

    @ID(key: .id) var id: UUID?
    @Field(key: "title") var title: String
    @Field(key: "is_done") var isDone: Bool

    init() {}
    init(id: UUID? = nil, title: String, isDone: Bool = false) {
        self.id = id
        self.title = title
        self.isDone = isDone
    }

    func toDTO() -> TodoDTO {
        .init(id: id, title: title, isDone: isDone)
    }
}

struct CreateTodo: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("todos")
            .id()
            .field("title", .string, .required)
            .field("is_done", .bool, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("todos").delete()
    }
}

struct UpdateTodo: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("todos")
            .field("created_at", .datetime, .required, .sql(.default(SQLRaw("NOW()"))))
            .update()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("todos").delete()
    }
}
