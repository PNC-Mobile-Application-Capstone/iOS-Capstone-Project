import CoreData
import Foundation
import Testing
@testable import AdventureWorksMobile

@Suite(.serialized)
@MainActor
struct RefreshRecoveryTests {
    @Test
    func productRetryClearsFailure() async {
        let repository = RecoveryRepository<Product>(result: .failure(URLError(.notConnectedToInternet)))
        let model = ProductList.ViewModel()
        await model.loadData(repository: repository)
        #expect(!model.errorMessage.isEmpty)

        repository.result = .success(([], .notcached))
        await model.loadData(repository: repository, forceRefresh: true)
        #expect(model.errorMessage.isEmpty)
    }

    @Test
    func orderRetryClearsFailure() async {
        let repository = RecoveryRepository<CustomerOrder>(result: .failure(URLError(.timedOut)))
        let model = CustomerOrderList.ViewModel()
        await model.loadData(repository: repository)
        #expect(!model.errorMessage.isEmpty)

        repository.result = .success(([], .notcached))
        await model.loadData(repository: repository, forceRefresh: true)
        #expect(model.errorMessage.isEmpty)
    }

    @Test
    func failedRefreshExplainsSavedProducts() async {
        let persistence = PersistenceController(inMemory: true)
        let product = Product(context: persistence.container.viewContext)
        product.id = 1
        product.name = "Road Bike"
        let repository = RecoveryRepository<Product>(result: .success(([product], .staleDisk)))
        let model = ProductList.ViewModel()
        await model.loadData(repository: repository, forceRefresh: true)
        #expect(model.items.all.map(\.id) == [1])
        #expect(!model.errorMessage.isEmpty)
    }

    @Test
    func listFailureHidesTechnicalStatusCode() async {
        let repository = RecoveryRepository<Product>(result: .failure(NetworkError.badResponse(statusCode: 503)))
        let model = ProductList.ViewModel()
        await model.loadData(repository: repository)
        #expect(!model.errorMessage.isEmpty)
        #expect(!model.errorMessage.contains("503"))
    }
    @Test
    func productLoadKeepsRefreshDistinctAndIgnoresDuplicateRequests() async {
        let gate = RecoveryGate()
        let repository = RecoveryRepository<Product>(result: .success(([], .notcached)))
        repository.gate = gate
        let model = ProductList.ViewModel()
        let initialLoad = Task { await model.loadData(repository: repository) }
        await gate.waitUntilStarted()
        #expect(model.isLoading)
        #expect(!model.hasLoaded)
        await model.loadData(repository: repository, forceRefresh: true)
        #expect(repository.requests == [false])
        await gate.open()
        await initialLoad.value
        #expect(!model.isLoading)
        #expect(model.hasLoaded)
        #expect(model.isEmpty)

        let refreshGate = RecoveryGate()
        repository.gate = refreshGate
        let refresh = Task { await model.loadData(repository: repository, forceRefresh: true) }
        await refreshGate.waitUntilStarted()
        #expect(model.isLoading && model.hasLoaded)
        await refreshGate.open()
        await refresh.value
        #expect(repository.requests == [false, true])
        #expect(!model.isLoading)
    }

    @Test
    func orderRefreshPreservesContentAndSearchAfterFailure() async {
        let persistence = PersistenceController(inMemory: true)
        let row = CustomerOrder(context: persistence.container.viewContext)
        row.id = 1
        row.orderNumber = 100
        row.firstName = "Jordan"
        let repository = RecoveryRepository<CustomerOrder>(result: .success(([row], .notcached)))
        let model = CustomerOrderList.ViewModel()
        await model.loadData(repository: repository)
        model.searchText = "jordan"
        model.sortOption = .newest
        repository.result = .failure(URLError(.notConnectedToInternet))
        await model.loadData(repository: repository, forceRefresh: true)
        #expect(model.orders.all.map(\.orderNumber) == [100])
        #expect(model.searchText == "jordan")
        #expect(model.sortOption == .newest)
        #expect(!model.errorMessage.isEmpty)
        #expect(!model.isLoading)

        repository.result = .success(([], .notcached))
        await model.loadData(repository: repository, forceRefresh: true)
        #expect(model.isEmpty && model.hasLoaded)
        #expect(model.errorMessage.isEmpty)
    }

    @Test
    func cancelledListLoadStopsWithoutAnErrorAndCanRetry() async {
        let repository = RecoveryRepository<Product>(result: .failure(URLError(.cancelled)))
        let model = ProductList.ViewModel()
        await model.loadData(repository: repository)
        #expect(!model.isLoading)
        #expect(!model.hasLoaded)
        #expect(model.errorMessage.isEmpty)
        repository.result = .success(([], .notcached))
        await model.loadData(repository: repository)
        #expect(model.hasLoaded)
    }

    @Test
    func returningToProductTabWaitsForCancelledLoadToFinish() async {
        let gate = RecoveryGate()
        let repository = RecoveryRepository<Product>(result: .failure(CancellationError()))
        repository.gate = gate
        let model = ProductList.ViewModel()
        let original = Task { await model.loadData(repository: repository) }
        await gate.waitUntilStarted()
        repository.result = .success(([], .notcached))
        let cleanup = Task { await gate.open() }
        await model.loadData(repository: repository)
        await cleanup.value
        await original.value
        #expect(model.hasLoaded)
        #expect(!model.isLoading)
        #expect(repository.requests == [false, false])
    }

    @Test
    func employeeAndInventoryRetryClearTheirErrors() async {
        let employees = RecoveryRepository<Employee>(result: .failure(URLError(.notConnectedToInternet)))
        let inventory = RecoveryRepository<Inventory>(result: .failure(URLError(.notConnectedToInternet)))
        let employeeModel = EmployeeList.ViewModel()
        let inventoryModel = InventoryList.ViewModel()
        await employeeModel.loadData(repository: employees)
        await inventoryModel.loadData(repository: inventory)
        #expect(!employeeModel.errorMessage.isEmpty)
        #expect(!inventoryModel.errorMessage.isEmpty)
        employees.result = .success(([], .notcached))
        inventory.result = .success(([], .notcached))
        await employeeModel.loadData(repository: employees, forceRefresh: true)
        await inventoryModel.loadData(repository: inventory, forceRefresh: true)
        #expect(employeeModel.hasLoaded && employeeModel.isEmpty && !employeeModel.isLoading)
        #expect(inventoryModel.hasLoaded && inventoryModel.isEmpty && !inventoryModel.isLoading)
        #expect(employeeModel.errorMessage.isEmpty)
        #expect(inventoryModel.errorMessage.isEmpty)
    }

}

@MainActor
private final class RecoveryRepository<Item: Codable & Identifiable>: TieredCacheRepositoryProtocol {
    var result: Result<([Item], CachedDataSource), Error>
    var gate: RecoveryGate?
    private(set) var requests: [Bool] = []

    init(result: Result<([Item], CachedDataSource), Error>) {
        self.result = result
    }

    func getAll(forceRefresh: Bool) async throws -> ([Item], CachedDataSource) {
        requests.append(forceRefresh)
        let result = self.result
        if let gate {
            self.gate = nil
            await gate.wait()
        }
        return try result.get()
    }
}

actor RecoveryGate {
    private var started = false
    private var startWaiter: CheckedContinuation<Void, Never>?
    private var release: CheckedContinuation<Void, Never>?

    func wait() async {
        await withCheckedContinuation { continuation in
            release = continuation
            started = true
            startWaiter?.resume()
            startWaiter = nil
        }
    }

    func waitUntilStarted() async {
        if started { return }
        await withCheckedContinuation { startWaiter = $0 }
    }

    func open() {
        release?.resume()
        release = nil
    }
}
