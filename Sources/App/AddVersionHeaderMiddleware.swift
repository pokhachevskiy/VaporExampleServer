//
//  AddVersionHeaderMiddleware.swift
//  TodoServerVapor
//
//  Created by Даниил Похачевский on 04.08.2025.
//

import Vapor

struct AddVersionHeaderMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let response = try await next.respond(to: request)
        response.headers.add(name: "My-App-Version", value: "v2.5.9")
        return response
    }
}

actor RateLimitStorage {
    private var requestLogs = [String: [Date]]()
    private let maxRequests: Int
    private let windowSeconds: TimeInterval

    init(maxRequests: Int, windowSeconds: TimeInterval) {
        self.maxRequests = maxRequests
        self.windowSeconds = windowSeconds
    }

    func isRateLimited(clientIP: String) -> Bool {
        let now = Date()
        let validTime = now.addingTimeInterval(-windowSeconds)
        let recentRequests = (requestLogs[clientIP] ?? []).filter { $0 > validTime }

        if recentRequests.count >= maxRequests {
            return true
        } else {
            requestLogs[clientIP, default: []].append(now)
            return false
        }
    }
}

struct RateLimitMiddleware: AsyncMiddleware {
    private let storage: RateLimitStorage

    init(maxRequests: Int, windowSeconds: TimeInterval) {
        self.storage = RateLimitStorage(maxRequests: maxRequests, windowSeconds: windowSeconds)
    }

    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let clientIP = request.remoteAddress?.ipAddress ?? "unknown"

        let isLimited = await storage.isRateLimited(clientIP: clientIP)

        if isLimited {
            return Response(status: .tooManyRequests)
        }

        return try await next.respond(to: request)
    }
}
