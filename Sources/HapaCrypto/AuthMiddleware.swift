import Foundation
import Hummingbird
import Logging

/// Middleware for Hapa Bearer Token authentication.
public struct HapaAuthMiddleware<Context: RequestContext>: RouterMiddleware {
    public let token: String

    public init(token: String) {
        self.token = token
    }

    public func handle(_ request: Request, context: Context, next: (Request, Context) async throws -> Response) async throws -> Response {
        guard let authHeader = request.headers[.authorization] else {
            throw HTTPError(.unauthorized, message: "Missing Authorization header")
        }

        let prefix = "Bearer "
        guard authHeader.hasPrefix(prefix) else {
            throw HTTPError(.unauthorized, message: "Invalid Authorization header format. Expected 'Bearer <token>'")
        }

        let providedToken = String(authHeader.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
        guard providedToken == token else {
            throw HTTPError(.unauthorized, message: "Invalid token")
        }

        return try await next(request, context)
    }
}

/// Helper to resolve or generate the node token.
public struct TokenManager {
    public static func resolveToken(rootPath: String) -> String {
        let tokenFile = URL(fileURLWithPath: rootPath).appendingPathComponent(".node_token")
        
        if let envToken = ProcessInfo.processInfo.environment["HAPA_CRYPTO_NODE_TOKEN"], !envToken.isEmpty {
            return envToken
        }
        
        if let fileToken = try? String(contentsOf: tokenFile, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines), !fileToken.isEmpty {
            return fileToken
        }
        
        let newToken = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        try? newToken.write(to: tokenFile, atomically: true, encoding: .utf8)
        print("Generated new node token and saved to .node_token")
        return newToken
    }
}
