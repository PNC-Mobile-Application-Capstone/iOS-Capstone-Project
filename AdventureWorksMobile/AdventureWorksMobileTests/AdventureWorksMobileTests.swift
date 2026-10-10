import CoreData
import Foundation
import Testing
@testable import AdventureWorksMobile

@Suite(.serialized)
@MainActor
struct AdventureWorksMobileTests {
    @Test
    func authenticationRequiresAndStoresBothTokens() {
        let store = InMemoryTokenStore()
        let status = AuthStatus(tokenStore: store)

        #expect(status.logIn(accessToken: "access", refreshToken: "refresh"))
        #expect(status.isLoggedIn)
        #expect(status.authToken == "access")
        #expect(status.refreshToken == "refresh")

        status.logout()
        #expect(!status.isLoggedIn)
        #expect(status.authToken == nil)
        #expect(status.refreshToken == nil)
    }

    @Test
    func failedTokenWriteLeavesTheUserLoggedOut() {
        let store = InMemoryTokenStore(failingKey: "userRefreshToken")
        let status = AuthStatus(tokenStore: store)

        #expect(!status.logIn(accessToken: "access", refreshToken: "refresh"))
        #expect(!status.isLoggedIn)
        #expect(store.values.isEmpty)
    }

    @Test
    func authServiceEncodesLoginAndDecodesSuccess() async throws {
        URLProtocolStub.handler = { request in
            #expect(request.httpMethod == "POST")
            let body = try #require(request.httpBody)
            let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: String])
            #expect(json["loginId"] == "employee")
            #expect(json["password"] == "secret")
            return Self.response(
                for: request,
                statusCode: 200,
                body: Data(
                    #"{"success":true,"userName":"employee","accessToken":"access","refreshToken":"refresh"}"#.utf8
                )
            )
        }

        let service = AuthService(session: Self.stubbedSession())
        let response = try await service.login(
            credentials: LoginModel(username: "employee", password: "secret")
        )

        #expect(response.success)
        #expect(response.accessToken == "access")
        #expect(response.refreshToken == "refresh")
    }

    @Test
    func authServiceReportsRejectedLogin() async {
        URLProtocolStub.handler = { request in
            Self.response(for: request, statusCode: 401, body: Data())
        }

        do {
            _ = try await AuthService(session: Self.stubbedSession()).login(
                credentials: LoginModel(username: "employee", password: "wrong")
            )
            Issue.record("Expected the login request to be rejected")
        } catch NetworkError.unauthorized {
            // Expected.
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func unauthorizedRequestRefreshesAndRetriesWithTheNewToken() async throws {
        let store = InMemoryTokenStore()
        let status = AuthStatus(tokenStore: store)
        #expect(status.logIn(accessToken: "old-access", refreshToken: "old-refresh"))

        var requestCount = 0
        URLProtocolStub.handler = { request in
            requestCount += 1
            if requestCount == 1 {
                #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer old-access")
                return Self.response(for: request, statusCode: 401, body: Data())
            }

            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer new-access")
            return Self.response(for: request,
                                 statusCode: 200,
                                 body: Data(#"[{"id":1,"name":"Road Bike"}]"#.utf8))
        }

        let authService = AuthServiceStub(
            refreshResult: .success(Self.loginResponse(accessToken: "new-access",
                                                       refreshToken: "new-refresh"))
        )
        let repository = RemoteRepositoryBase<SampleItem>(
            authStatus: status,
            session: Self.stubbedSession(),
            authService: authService
        )

        let items = try await repository.fetchAll("https://example.test/items")

        #expect(items == [SampleItem(id: 1, name: "Road Bike")])
        #expect(requestCount == 2)
        #expect(status.authToken == "new-access")
        #expect(status.refreshToken == "new-refresh")
    }

    @Test
    func rejectedRefreshLogsTheUserOut() async {
        let store = InMemoryTokenStore()
        let status = AuthStatus(tokenStore: store)
        #expect(status.logIn(accessToken: "expired", refreshToken: "rejected"))

        URLProtocolStub.handler = { request in
            Self.response(for: request, statusCode: 401, body: Data())
        }

        let repository = RemoteRepositoryBase<SampleItem>(
            authStatus: status,
            session: Self.stubbedSession(),
            authService: AuthServiceStub(refreshResult: .failure(NetworkError.unauthorized))
        )

        do {
            _ = try await repository.fetchAll("https://example.test/items")
            Issue.record("Expected the request to fail as unauthorized")
        } catch NetworkError.unauthorized {
            #expect(!status.isLoggedIn)
            #expect(status.authToken == nil)
            #expect(status.refreshToken == nil)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func productDecodingAcceptsNullableFieldsAndEncodesProductNumber() throws {
        let context = PersistenceController(inMemory: true).container.viewContext
        let decoder = JSONDecoder()
        decoder.userInfo[.managedObjectContext] = context
        let data = Data(
            #"{"productId":42,"name":null,"color":null,"listPrice":12.5,"productNumber":"AW-42"}"#.utf8
        )

        let product = try decoder.decode(Product.self, from: data)
        let encoded = try JSONEncoder().encode(product)
        let json = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])

        #expect(product.id == 42)
        #expect(product.name == nil)
        #expect(product.productNumber == "AW-42")
        #expect(json["productNumber"] as? String == "AW-42")
    }

    @Test
    func productRepositoryUsesMemoryThenDiskAndFallsBackToStaleDisk() async throws {
        let persistence = PersistenceController(inMemory: true)
        let store = InMemoryTokenStore()
        let status = AuthStatus(tokenStore: store)
        #expect(status.logIn(accessToken: "access", refreshToken: "refresh"))

        let suiteName = "AdventureWorksMobileTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        var currentDate = Date(timeIntervalSince1970: 1_000)
        URLProtocolStub.handler = { request in
            Self.response(
                for: request,
                statusCode: 200,
                body: Data(
                    #"[{"productId":1,"name":"Road Bike","color":null,"listPrice":99.5,"productNumber":"RB-1"}]"#.utf8
                )
            )
        }

        let session = Self.stubbedSession()
        let repository = TieredCacheRepositoryBase<Product>(
            authStatus: status,
            urlBase: "https://example.test/api/product",
            context: persistence.container.viewContext,
            session: session,
            defaults: defaults,
            now: { currentDate }
        )

        let (networkItems, networkSource) = try await repository.getAll()
        let (_, memorySource) = try await repository.getAll()
        #expect(networkItems.count == 1)
        #expect(networkSource == .notcached)
        #expect(memorySource == .memory)

        let diskRepository = TieredCacheRepositoryBase<Product>(
            authStatus: status,
            urlBase: "https://example.test/api/product",
            context: persistence.container.viewContext,
            session: session,
            defaults: defaults,
            now: { currentDate }
        )
        let (_, diskSource) = try await diskRepository.getAll()
        #expect(diskSource == .disk)

        currentDate.addTimeInterval(16 * 60)
        URLProtocolStub.handler = { _ in throw URLError(.notConnectedToInternet) }
        let offlineRepository = TieredCacheRepositoryBase<Product>(
            authStatus: status,
            urlBase: "https://example.test/api/product",
            context: persistence.container.viewContext,
            session: session,
            defaults: defaults,
            now: { currentDate }
        )
        let (offlineItems, offlineSource) = try await offlineRepository.getAll()
        #expect(offlineItems.count == 1)
        #expect(offlineSource == .staleDisk)
    }

    private static func stubbedSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: configuration)
    }

    private static func response(for request: URLRequest,
                                 statusCode: Int,
                                 body: Data) -> (HTTPURLResponse, Data) {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        return (response, body)
    }

    private static func loginResponse(accessToken: String,
                                      refreshToken: String) -> LoginResponse {
        LoginResponse(
            success: true,
            userName: "test",
            accessToken: accessToken,
            refreshToken: refreshToken,
            accessExpiry: nil,
            refreshExpiry: nil
        )
    }
}

private struct SampleItem: Codable, Equatable {
    let id: Int
    let name: String
}

private final class InMemoryTokenStore: TokenStoring {
    var values: [String: String] = [:]
    private let failingKey: String?

    init(failingKey: String? = nil) {
        self.failingKey = failingKey
    }

    func saveToken(_ token: String, key: String) -> Bool {
        guard key != failingKey else { return false }
        values[key] = token
        return true
    }

    func getToken(key: String) -> String? {
        values[key]
    }

    func deleteToken(key: String) {
        values.removeValue(forKey: key)
    }
}

private final class AuthServiceStub: AuthServicing {
    private let refreshResult: Result<LoginResponse, Error>

    init(refreshResult: Result<LoginResponse, Error>) {
        self.refreshResult = refreshResult
    }

    func login(credentials: LoginModel) async throws -> LoginResponse {
        throw NetworkError.badResponse(statusCode: 501)
    }

    func refreshToken(authToken: String, refreshToken: String) async throws -> LoginResponse {
        try refreshResult.get()
    }
}

private final class URLProtocolStub: URLProtocol {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
