import Vapor
import Fluent
import FluentSQL

func routes(_ app: Application) throws {
    try app.register(collection: TodosController())
    app.get("something") { req in
        return "something string"
    }

    app.post("hello") { req in
        return HTTPStatus.accepted
    }
}

struct TodosController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let todos = routes.grouped("todos")
        todos.get("new", use: indexNew)
        todos.get(use: index)
        todos.post(use: create)

        todos.group(":id") { todo in
            todo.get(use: show)
            todo.put(use: update)
            todo.delete(use: delete)
        }

        let rateLimitedFiles = routes.grouped(RateLimitMiddleware(maxRequests: 2, windowSeconds: 5))
        rateLimitedFiles.get("public", "**") { req async throws -> Response in
            let fileMiddleware = FileMiddleware(publicDirectory: "Public")
            return try await fileMiddleware.respond(
                to: req,
                chainingTo: AsyncBasicResponder(
                    closure: { _ in try await HTTPStatus.ok.encodeResponse(for: req) }
                )
            )
        }
    }

    func index(req: Request) async throws -> [TodoDTO] {
        try await Todo.query(on: req.db).all().map { $0.toDTO() }
    }

    func indexNew(req: Request) async throws -> [TodoDTO] {
        if let db = req.db as? SQLDatabase {
            return try await db.raw("SELECT * FROM todos ORDER BY created_at DESC").all(decoding: TodoRawDTO.self).map { $0.toDTO() }
        } else {
            return []
        }
    }

    func create(req: Request) async throws -> TodoDTO {
        let todo = try req.content.decode(TodoDTO.self)
        try await todo.toModel().save(on: req.db)
        return todo
    }

    func show(req: Request) async throws -> TodoDTO {
        guard let todo = try await Todo.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        return todo.toDTO()
    }

    func update(req: Request) async throws -> TodoDTO {
        guard let todo = try await Todo.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        let updatedTodo = try req.content.decode(TodoDTO.self)
        todo.isDone = updatedTodo.isDone ?? false
        todo.title = updatedTodo.title
        try await todo.update(on: req.db)
        return updatedTodo
    }

    func delete(req: Request) async throws -> HTTPStatus {
        guard let todo = try await Todo.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await todo.delete(on: req.db)
        return .ok
    }
}
