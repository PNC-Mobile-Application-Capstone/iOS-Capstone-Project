//
//  AuthService.swift
//  AdventureWorksMobile
//

import Foundation

// Lets tests swap in a fake auth service.
protocol AuthServicing {
    func login(credentials: LoginModel) async throws -> LoginResponse
    func refreshToken(authToken: String, refreshToken: String) async throws -> LoginResponse
}

// JSON body for the refresh call.
private struct RefreshTokenRequest: Encodable {
    let refreshToken: String
}

/// Makes the login and refresh calls. It holds no tokens. AuthStatus and SecureTokenManager do that.
final class AuthService: AuthServicing {
    // One shared instance for the app. Tests create their own with a stub URLSession.
    static let shared = AuthService()
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// POST /api/Login. Returns the tokens on success.
    func login(credentials: LoginModel) async throws -> LoginResponse {

        guard let url = APIEndpoint.login.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // LoginModel is Codable, so JSONEncoder turns it into the request body.
        let encoder = JSONEncoder()
        do {
            request.httpBody = try encoder.encode(credentials)
        }
        catch {
            throw NetworkError.encodingFailed(underlying: error)
        }

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.badResponse(statusCode: -1)
        }

        guard (200...299).contains(http.statusCode) else {
            if http.statusCode == 401 {
                throw NetworkError.unauthorized
            }
            throw NetworkError.badResponse(statusCode: http.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            // Map snake_case JSON keys to camelCase properties.
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            // Decode ISO 8601 date strings (see JSONDecoderExt.swift).
            decoder.useStringDecoderForDate()

            return try decoder.decode(LoginResponse.self, from: data)
        }
        catch {
            throw NetworkError.decodingFailed(underlying: error)
        }

    }


    /// POST /api/Login/refresh. Trades the old tokens for a new pair after a 401.
    func refreshToken(authToken: String, refreshToken: String) async throws -> LoginResponse {

        guard let url = APIEndpoint.refreshToken.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // The expired access token still goes in the header so the server knows which session to renew.
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONEncoder().encode(RefreshTokenRequest(refreshToken: refreshToken))
        } catch {
            throw NetworkError.encodingFailed(underlying: error)
        }

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.badResponse(statusCode: -1)
        }

        guard (200...299).contains(http.statusCode) else {
            if http.statusCode == 401 {
                // The refresh token is bad too, so the user must sign in again.
                throw NetworkError.unauthorized
            }
            throw NetworkError.badResponse(statusCode: http.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.useStringDecoderForDate()

            return try decoder.decode(LoginResponse.self, from: data)
        }
        catch {
            throw NetworkError.decodingFailed(underlying: error)
        }


    }


}
