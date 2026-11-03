//
//  RemoteRepositoryBase.swift
//  AdventureWorksMobile
//

import Foundation
internal import CoreData

/// Shared request, error, and token-refresh code. Item is any Codable type, like Product.
@MainActor
class RemoteRepositoryBase<Item: Codable> {

    // Used to attach the access token and to refresh it after a 401.
    private var authStatus: AuthStatus
    private let session: URLSession
    private let authService: any AuthServicing
    // When set, decoding creates Core Data objects in this context.
    var implicitContext: NSManagedObjectContext? = nil

    init(authStatus: AuthStatus,
         session: URLSession = .shared,
         authService: (any AuthServicing)? = nil) {
        self.authStatus = authStatus
        self.session = session
        // Tests pass a stub. The app uses the shared AuthService.
        self.authService = authService ?? AuthService.shared
    }

    // MARK: - fetchAll method

    func fetchAll(_ urlString: String) async throws -> [Item] {

        // Build the request, send it, then decode the JSON.
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

    /// Decodes any shape, not just Item. Used for partial responses like a product photo.
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

        do {
            request.httpBody = try JSONEncoder().encode(item)
        }
        catch {
            throw NetworkError.encodingFailed(underlying: error)
        }

        // PUT sends back nothing we need, so the data is ignored.
        let _ = try await executeRequest(request)

    }

    // MARK: - delete method

    func del(_ urlString: String) async throws {

        var request = try createRequest(urlString)
        request.httpMethod = "DELETE"

        let _ = try await executeRequest(request)
    }


    // MARK: - Private utility methods

    /// Builds the request with the Bearer token. Logs out and throws if there is no token.
    private func createRequest(_ urlString: String) throws -> URLRequest {

        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        guard let auth = authStatus.authToken, !auth.isEmpty else {
            authStatus.logout(sessionExpired: true)
            throw NetworkError.missingAuthToken
        }
        request.setValue("Bearer \(auth)", forHTTPHeaderField: "Authorization")


        return request
    }

    /// Sends the request. On a 401 it refreshes the token once and retries. isRetry stops a loop.
    private func executeRequest(_ request: URLRequest, isRetry: Bool = false) async throws -> Data {

        let (data, response) = try await session.data(for: request)

        // Cast to HTTPURLResponse to read the status code.
        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.badResponse(statusCode: -1)
        }

        guard (200...299).contains(http.statusCode) else {
            if http.statusCode == 401 {

                // Only refresh on the first try and when both tokens exist. Otherwise log out.
                guard !isRetry,
                      let refresh = authStatus.refreshToken, !refresh.isEmpty,
                      let auth = authStatus.authToken, !auth.isEmpty else {
                    authStatus.logout(sessionExpired: true)
                    throw NetworkError.unauthorized
                }

                // Any refresh failure that means the tokens are bad logs the user out.
                let refreshResult: LoginResponse
                do {
                    refreshResult = try await authService.refreshToken(authToken: auth,
                                                                       refreshToken: refresh)
                } catch NetworkError.unauthorized {
                    authStatus.logout(sessionExpired: true)
                    throw NetworkError.unauthorized
                } catch NetworkError.badResponse(let statusCode) where (400...499).contains(statusCode) {
                    authStatus.logout(sessionExpired: true)
                    throw NetworkError.unauthorized
                } catch NetworkError.decodingFailed {
                    authStatus.logout(sessionExpired: true)
                    throw NetworkError.unauthorized
                }

                // Save the new tokens, or log out if that fails.
                guard refreshResult.success,
                      authStatus.logIn(accessToken: refreshResult.accessToken,
                                       refreshToken: refreshResult.refreshToken),
                      let refreshedAccessToken = authStatus.authToken else {
                    authStatus.logout(sessionExpired: true)
                    throw NetworkError.unauthorized
                }

                var newRequest = request
                newRequest.setValue("Bearer \(refreshedAccessToken)", forHTTPHeaderField: "Authorization")

                // Replay the request with the new token. isRetry: true stops a second refresh.
                return try await executeRequest(newRequest, isRetry: true)
            }
            throw NetworkError.badResponse(statusCode: http.statusCode)
        }

        return data
    }

    // Decodes JSON. With a Core Data context, it runs on that context's queue.
    private func decode<Value: Decodable>(_ type: Value.Type, from data: Data) async throws -> Value {
        // Keep the decode steps in a closure so they can run inside or outside context.perform.
        let decodeValue = {
            let decoder = JSONDecoder()
            if let context = self.implicitContext {
                decoder.userInfo[CodingUserInfoKey.managedObjectContext] = context
            }
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.useStringDecoderForDate()
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
