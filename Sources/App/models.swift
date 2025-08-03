import Vapor
import Fluent

final class Todo: Model, Content {
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