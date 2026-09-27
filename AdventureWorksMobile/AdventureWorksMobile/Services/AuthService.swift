//
//  AuthService.swift
//  SwiftUIDemo
//
//  Created by Tyler Swindell on 9/15/26.
//

import Foundation

/// Handles the two network calls that make up the authentication flow:
/// logging in with a username/password, and exchanging a refresh token
/// for a fresh access token when the current one expires.
///
/// `AuthService` itself is stateless. It does not hold on to any tokens;
/// it just knows how to talk to the login endpoints and hand back a
/// decoded `LoginResponse`. Storing/retrieving the tokens is the job of
/// `SecureTokenManager`, and tracking whether the user is logged in is
/// the job of `AuthStatus`.
class AuthService {
    // Singleton pattern: one shared instance for the whole app instead of
    // creating a new AuthService every time a login/refresh call is made.
    // The private init() below is what prevents anyone else from calling
    // AuthService() directly, so `.shared` is the only way to get one.
    static let shared = AuthService()
    
    private init() {}
    
    /// Calls POST /api/Login with the user's credentials and returns the
    /// decoded response (which includes the access token and refresh
    /// token on success).
    func login(credentials: LoginModel) async throws -> LoginResponse {
        
        let urlString = "https://api.bootcampcentral.com/api/Login"
        
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // LoginModel conforms to Codable, so JSONEncoder can turn it
        // straight into the JSON body of the request.
        let encoder = JSONEncoder()
        do {
            request.httpBody = try encoder.encode(credentials)
        }
        catch {
            throw NetworkError.encodingFailed(underlying: error)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
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
            // API returns snake_case keys (e.g. access_token); this maps
            // them to the camelCase properties on LoginResponse automatically.
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            // Custom date strategy (defined in JSONDecoderExt.swift) so the
            // ISO 8601 date strings the API sends decode into real Date values.
            decoder.useStringDecoderForDate()
            
            return try decoder.decode(LoginResponse.self, from: data)
        }
        catch {
            throw NetworkError.decodingFailed(underlying: error)
        }
        
    }
    
    
    /// Calls POST /api/Login/refresh to trade an (expired) access token and
    /// a still-valid refresh token for a brand new pair of tokens.
    ///
    /// This is what RemoteRepositoryBase calls automatically when a request
    /// comes back 401, so the user doesn't have to log in again every time
    /// their access token expires.
    func refreshToken(authToken: String, refreshToken: String) async throws -> LoginResponse {
        
        let urlString = "https://api.bootcampcentral.com/api/Login/refresh"
        
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Even though this token may be expired, it still gets sent in the
        // Authorization header; the refresh endpoint uses it (together with
        // the refresh token below) to identify which session to renew.
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        // Built by hand here instead of going through JSONEncoder since it's
        // just a single field.
        let bodyString = "{\"refreshToken\":\"\(refreshToken)\"}"
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.badResponse(statusCode: -1)
        }
        
        guard (200...299).contains(http.statusCode) else {
            if http.statusCode == 401 {
                // Refresh token itself is invalid/expired; caller needs to
                // send the user back to the login screen.
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
