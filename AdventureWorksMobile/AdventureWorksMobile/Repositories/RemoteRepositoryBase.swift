//
//  RemoteRepositoryBase.swift
//  SwiftUIDemo
//
//  Created by Tyler Swindell on 9/14/26.
//

import Foundation
internal import CoreData

/// Generic base class that all the "remote repository" classes
/// feature-specific repositories inherit
/// from, so each one doesn't have to re-implement request building,
/// error handling, and auth-token refreshing on its own.
///
/// `<Item: Codable>` is a generic wrapper: RemoteRepositoryBase doesn't
/// know or care what "Item" actually is at compile time as long as it's
/// Codable. Each subclass fills in the
/// concrete type, e.g. `RemoteRepositoryBase<Product>`.
@MainActor
class RemoteRepositoryBase<Item: Codable> {

    // Kept so every request this repository makes can attach the current
    // access token, and so a 401 can trigger a refresh using the stored
    // refresh token.
    private var authStatus: AuthStatus
    private let session: URLSession
    private let authService: any AuthServicing
    var implicitContext: NSManagedObjectContext? = nil

    init(authStatus: AuthStatus,
         session: URLSession = .shared,
         authService: any AuthServicing = AuthService.shared) {
        self.authStatus = authStatus
        self.session = session
        self.authService = authService
    }

    // MARK: - fetchAll method

    func fetchAll(_ urlString: String) async throws -> [Item] {

        let request = try createRequest(urlString)
        let data = try await executeRequest(request)

        do {
            return try await decode([Item].self, from: data)
        } catch {
            throw NetworkError.decodingFailed(underlying: error)
        }

    }

    // MARK: - fetchOne method

    func fetchOne(_ urlString: String) async throws -> Item {

        let request = try createRequest(urlString)
        let data = try await executeRequest(request)

        do {
            return try await decode(Item.self, from: data)
        }
        catch {
            throw NetworkError.decodingFailed(underlying: error)
        }
    }
    
    // MARK: - fetchDecoded method

    /// Fetches any Decodable shape from an endpoint, not just Item.
    /// Used for partial responses, like loading only a product's photo.
    func fetchDecoded<T: Decodable>(_ urlString: String, as type: T.Type) async throws -> T {
        let request = try createRequest(urlString)
        let data = try await executeRequest(request)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(underlying: error)
        }
    }

    // MARK: - post method

    func post(_ urlString: String, send item: Item) async throws -> Item {

        var request = try createRequest(urlString)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")


        do {
            request.httpBody = try JSONEncoder().encode(item)
        }
        catch {
            throw NetworkError.encodingFailed(underlying: error)
        }

        let data = try await executeRequest(request)

        do {
            return try await decode(Item.self, from: data)
        }
        catch {
            throw NetworkError.decodingFailed(underlying: error)
        }
    }

    // MARK: - put method

    func put(_ urlString: String, send item: Item) async throws {

        var request = try createRequest(urlString)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // ultimately we will add authorization to this request

        do {
            request.httpBody = try JSONEncoder().encode(item)
        }
        catch {
            throw NetworkError.encodingFailed(underlying: error)
        }

        let _ = try await executeRequest(request)

    }

    // MARK: - delete method

    func del(_ urlString: String) async throws {

        var request = try createRequest(urlString)
        request.httpMethod = "DELETE"

        let _ = try await executeRequest(request)
    }


    // MARK: - Private utility methods

    /// Builds a URLRequest and attaches the current access token as a
    /// Bearer header. Throws .missingAuthToken if there isn't one, which
    /// stops a request from ever going out unauthenticated.
    private func createRequest(_ urlString: String) throws -> URLRequest {

        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        guard let auth = authStatus.authToken, !auth.isEmpty else {
            authStatus.logout()
            throw NetworkError.missingAuthToken
        }
        request.setValue("Bearer \(auth)", forHTTPHeaderField: "Authorization")


        return request
    }

    /// Sends the request and, if it comes back with a 401, automatically
    /// tries to refresh the access token once and replay the request
    /// before giving up. This is the core of the refresh-token flow: every
    /// repository call (fetchAll, post, put, etc.) goes through here, so
    /// none of them have to handle expired tokens individually.
    ///
    /// `isRetry` is what prevents an infinite loop: if the retried request
    /// also comes back 401, we don't try to refresh again, we just fail.
    private func executeRequest(_ request: URLRequest, isRetry: Bool = false) async throws -> Data {

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.badResponse(statusCode: -1)
        }

        guard (200...299).contains(http.statusCode) else {
            if http.statusCode == 401 {

                // Only attempt a refresh if: this isn't already a retry,
                // and we actually have both tokens to work with. If any of
                // that isn't true there's nothing to refresh with, so just
                // surface .unauthorized and let the UI send the user back
                // to LoginView.
                guard !isRetry,
                      let refresh = authStatus.refreshToken, !refresh.isEmpty,
                      let auth = authStatus.authToken, !auth.isEmpty else {
                    authStatus.logout()
                    throw NetworkError.unauthorized
                }

                let refreshResult: LoginResponse
                do {
                    refreshResult = try await authService.refreshToken(authToken: auth,
                                                                       refreshToken: refresh)
                } catch NetworkError.unauthorized {
                    authStatus.logout()
                    throw NetworkError.unauthorized
                } catch NetworkError.badResponse(let statusCode) where (400...499).contains(statusCode) {
                    authStatus.logout()
                    throw NetworkError.unauthorized
                } catch NetworkError.decodingFailed {
                    authStatus.logout()
                    throw NetworkError.unauthorized
                }

                guard refreshResult.success,
                      authStatus.logIn(accessToken: refreshResult.accessToken,
                                       refreshToken: refreshResult.refreshToken),
                      let refreshedAccessToken = authStatus.authToken else {
                    authStatus.logout()
                    throw NetworkError.unauthorized
                }

                var newRequest = request
                newRequest.setValue("Bearer \(refreshedAccessToken)", forHTTPHeaderField: "Authorization")

                // Replay the original request with the new token. isRetry:
                // true here so if this second attempt also 401s, we stop
                // instead of refreshing forever.
                return try await executeRequest(newRequest, isRetry: true)
            }
            throw NetworkError.badResponse(statusCode: http.statusCode)
        }

        return data
    }

    private func decode<Value: Decodable>(_ type: Value.Type, from data: Data) async throws -> Value {
        let decodeValue = {
            let decoder = JSONDecoder()
            if let context = self.implicitContext {
                decoder.userInfo[CodingUserInfoKey.managedObjectContext] = context
            }
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(type, from: data)
        }

        if let context = implicitContext {
            return try await context.perform {
                try decodeValue()
            }
        }
        return try decodeValue()
    }
}
