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
            #expect(status.sessionMessage == "Your session expired. Please sign in again.")
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

    @Test
    func savedSessionIsRestoredAndExpiryMessageClearsOnLoginAndLogout() {
        let store = InMemoryTokenStore()
        let original = AuthStatus(tokenStore: store)
        #expect(original.logIn(accessToken: "access", refreshToken: "refresh"))
        let restored = AuthStatus(tokenStore: store)
        #expect(restored.isLoggedIn)

        restored.logout(sessionExpired: true)
        #expect(!restored.isLoggedIn)
        #expect(restored.sessionMessage == "Your session expired. Please sign in again.")
        #expect(store.values.isEmpty)

        #expect(restored.logIn(accessToken: "new-access", refreshToken: "new-refresh"))
        #expect(restored.sessionMessage == nil)
        restored.logout(sessionExpired: true)
        restored.logout()
        #expect(restored.sessionMessage == nil)
    }

    @Test
    func loginRejectionsShowCredentialMessageAndStopLoading() async {
        let rejected = LoginResponse(success: false)
        let results: [Result<LoginResponse, Error>] = [.success(rejected), .failure(NetworkError.unauthorized)]
        for result in results {
            let model = LoginView.ViewModel(authService: LoginServiceStub(result: result))
            #expect(await model.login() == nil)
            #expect(model.errorMessage == "Incorrect username or password.")
            #expect(!model.isBusy)
        }
    }

    @Test
    func loginHidesTechnicalErrorsAndClearsOldErrorsOnRetry() async {
        let model = LoginView.ViewModel(authService: LoginServiceStub(
            result: .failure(NetworkError.badResponse(statusCode: 503))))
        #expect(await model.login() == nil)
        #expect(model.errorMessage == "Unable to sign in. Please try again.")
        #expect(!model.isBusy)

        let successful = LoginView.ViewModel(authService: LoginServiceStub(
            result: .success(Self.loginResponse(accessToken: "access", refreshToken: "refresh"))))
        successful.errorMessage = "Previous error"
        #expect(await successful.login() != nil)
        #expect(successful.errorMessage.isEmpty)
        #expect(!successful.isBusy)
    }

    @Test
    func productDiscoverySearchesBeyondFirstPageAndResetsCriteria() {
        let context = PersistenceController(inMemory: true).container.viewContext
        let products = (1...30).map { index in
            let product = Product(context: context)
            product.id = Int64(index)
            product.name = "Bike \(index)"
            product.productNumber = "AW-\(index)"
            product.listPrice = Double(index)
            return product
        }
        let model = ProductList.ViewModel()
        model.setProducts(products)
        #expect(model.items.shown.count == 25)
        model.items.loadMore()
        #expect(model.items.shown.count == 30)

        model.searchText = "  aw-30  "
        #expect(model.items.all.map(\.id) == [30])
        #expect(model.hasActiveCriteria)
        model.searchText = "BIKE"
        model.sortOption = .priceDescending
        #expect(model.items.all.first?.id == 30)
        #expect(model.items.all.last?.id == 1)
        #expect(model.items.shown.count == 25)
        model.sortOption = .priceAscending
        #expect(model.items.all.first?.id == 1)
        model.searchText = "no matching record"
        #expect(model.items.all.isEmpty)

        model.clearCriteria()
        #expect(model.searchText.isEmpty)
        #expect(model.sortOption == .name)
        #expect(!model.hasActiveCriteria)
        #expect(model.items.all.count == 30)
        #expect(model.items.shown.count == 25)
    }

    @Test
    func productPriceTiesUseNameThenIDAndAcceptMissingNames() {
        let context = PersistenceController(inMemory: true).container.viewContext
        let products = ["Beta", "Alpha", "Alpha", nil].enumerated().map { index, name in
            let product = Product(context: context)
            product.id = Int64(index + 1)
            product.name = name
            product.listPrice = 10
            return product
        }
        let model = ProductList.ViewModel()
        model.setProducts(products)
        model.sortOption = .priceAscending
        #expect(model.items.all.map(\.id) == [4, 2, 3, 1])
        model.sortOption = .priceDescending
        #expect(model.items.all.map(\.id) == [4, 2, 3, 1])
    }

    @Test
    func orderDiscoveryCombinesCustomerSearchAndDateSorting() {
        let context = PersistenceController(inMemory: true).container.viewContext
        func group(_ number: Int64, _ name: String, _ date: String?) -> OrderGroup {
            let row = CustomerOrder(context: context)
            row.id = number
            row.orderNumber = number
            row.firstName = name
            row.lastName = "Lee"
            row.orderDate = date
            return OrderGroup(orderNumber: number, rows: [row])
        }
        let groups = [
            group(100, "Jordan", "2026-10-15T23:00:00-04:00"),
            group(200, "Jordan", "2026-10-16T02:00:00Z"),
            group(300, "Jordan", "not a date"),
            group(400, "Priya", "2026-10-17"),
            group(500, "Jordan", nil)
        ]
        let model = CustomerOrderList.ViewModel()
        model.setOrders(groups)
        model.searchText = "  jOrDaN  "
        model.sortOption = .newest
        #expect(model.orders.all.map(\.id) == [100, 200, 300, 500])
        model.sortOption = .oldest
        #expect(model.orders.all.map(\.id) == [200, 100, 300, 500])
        model.searchText = "40"
        #expect(model.orders.all.map(\.id) == [400])
        model.searchText = "no matching customer"
        #expect(model.orders.all.isEmpty)
        model.clearCriteria()
        #expect(model.orders.all.map(\.id) == [100, 200, 300, 400, 500])
        #expect(model.searchText.isEmpty)
        #expect(!model.hasActiveCriteria)
    }

    @Test
    func orderDiscoverySearchesBeyondFirstPageAndResetsPaging() {
        let context = PersistenceController(inMemory: true).container.viewContext
        let groups = (1...30).map { index in
            let row = CustomerOrder(context: context)
            row.id = Int64(index)
            row.orderNumber = Int64(index)
            row.firstName = "Customer"
            row.orderDate = "2026-10-16"
            return OrderGroup(orderNumber: row.orderNumber, rows: [row])
        }
        let model = CustomerOrderList.ViewModel()
        model.setOrders(groups)
        model.orders.loadMore()
        #expect(model.orders.shown.count == 30)
        model.searchText = "30"
        #expect(model.orders.all.map(\.id) == [30])
        model.clearCriteria()
        #expect(model.orders.all.count == 30)
        #expect(model.orders.shown.count == 25)
        model.sortOption = .newest
        #expect(model.orders.all.map(\.id) == Array(1...30).map(Int64.init))
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

private struct LoginServiceStub: AuthServicing {
    let result: Result<LoginResponse, Error>

    func login(credentials: LoginModel) async throws -> LoginResponse {
        try result.get()
    }

    func refreshToken(authToken: String, refreshToken: String) async throws -> LoginResponse {
        throw NetworkError.unauthorized
    }
}
