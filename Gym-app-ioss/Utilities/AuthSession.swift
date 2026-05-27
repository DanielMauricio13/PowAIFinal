import Foundation
import KeychainAccess

enum AuthSession {
    private static let tokenKey = "jwtToken"
    private static let keychain = Keychain(service: Bundle.main.bundleIdentifier ?? "PowAI")

    static func saveToken(_ token: String) {
        do {
            try keychain.set(token, key: tokenKey)
        } catch {
            print("Failed to save JWT token to keychain: \(error)")
        }
    }

    static func getToken() -> String? {
        do {
            return try keychain.get(tokenKey)
        } catch {
            print("Failed to read JWT token from keychain: \(error)")
            return nil
        }
    }

    static func clearToken() {
        do {
            try keychain.remove(tokenKey)
        } catch {
            print("Failed to clear JWT token from keychain: \(error)")
        }
    }
}

extension URLRequest {
    mutating func applyBearerToken() {
        if let token = AuthSession.getToken(), !token.isEmpty {
            setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }
}
