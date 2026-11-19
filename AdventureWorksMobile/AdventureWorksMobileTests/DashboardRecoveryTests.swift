import Foundation
import Testing
@testable import AdventureWorksMobile

@Suite(.serialized)
@MainActor
struct DashboardRecoveryTests {
    @Test
    func revisitingDashboardDoesNotReloadCompletedRequests() async {
        let repository = DashboardRecoveryRepository()
        let model = DashboardView.ViewModel(repository: repository)
        await model.loadData()
        await model.loadData()
        #expect(repository.requests == [1, 1, 1, 1])
        #expect(model.totalSales == 100)
    }

    @Test
    func dashboardIgnoresAnotherLoadWhileRequestsAreRunning() async {
        let repository = DashboardRecoveryRepository()
        let gate = RecoveryGate()
        repository.salesGate = gate
        let model = DashboardView.ViewModel(repository: repository)
        let first = Task { await model.loadData() }
        await gate.waitUntilStarted()
        let completion = Task { await gate.open() }
        await model.loadData()
        await completion.value
        await first.value
        #expect(repository.requests == [1, 1, 1, 1])
    }

    @Test
    func dashboardStillLoadsOtherSectionsWhenSalesFail() async {
        let repository = DashboardRecoveryRepository()
        repository.salesResult = .failure(URLError(.notConnectedToInternet))
        let model = DashboardView.ViewModel(repository: repository)
        await model.loadData()
        #expect(model.weeklySales.isEmpty)
        #expect(!model.loadedSections.contains(.sales))
        #expect(model.errors[.sales] != nil)
        #expect(!model.isLoading)
        #expect(model.productPerformance.map(\.productId) == [7])
        #expect(model.lowStock.map(\.productId) == [8])
        #expect(model.shifts.map(\.employeeId) == [9])
    }
    @Test
    func retryOnlyRequestsTheFailedDashboardSection() async {
        let repository = DashboardRecoveryRepository()
        repository.salesResult = .failure(NetworkError.badResponse(statusCode: 503))
        let model = DashboardView.ViewModel(repository: repository)
        await model.loadData()
        #expect(model.errors[.sales] != nil)
        #expect(model.errors[.sales]?.contains("503") == false)
        repository.salesResult = .success([
            WeeklySalesEntry(salesDate: Date(timeIntervalSince1970: 0), totalSales: 250, totalProfit: 50)
        ])
        await model.retry(.sales)
        #expect(model.totalSales == 250)
        #expect(model.errors[.sales] == nil)
        #expect(model.loadedSections.count == 4)
        #expect(repository.requests == [2, 1, 1, 1])
    }

    @Test
    func dashboardRefreshRetainsOldContentOnSectionFailure() async {
        let repository = DashboardRecoveryRepository()
        let model = DashboardView.ViewModel(repository: repository)
        await model.loadData()
        repository.salesResult = .failure(URLError(.notConnectedToInternet))
        repository.performanceResult = .success([
            ProductPerformanceEntry(productId: 10, productName: "Helmet", unitsSold: 4, unitsInStock: 8)
        ])
        await model.loadData(forceRefresh: true)
        #expect(model.totalSales == 100)
        #expect(model.errors[.sales] != nil)
        #expect(model.productPerformance.map(\.productId) == [10])
        #expect(!model.isLoading)
    }

    @Test
    func dashboardEmptySuccessIsDifferentFromFailure() async {
        let repository = DashboardRecoveryRepository()
        repository.salesResult = .success([])
        repository.performanceResult = .success([])
        repository.stockResult = .success([])
        repository.shiftsResult = .success([])
        let model = DashboardView.ViewModel(repository: repository)
        await model.loadData()
        #expect(model.loadedSections.count == 4)
        #expect(model.errors.isEmpty)
        #expect(model.hasLoaded)
        #expect(!model.isLoading)
    }

    @Test
    func cancelledDashboardSectionCanRetryWithoutAnError() async {
        let repository = DashboardRecoveryRepository()
        repository.salesResult = .failure(CancellationError())
        let model = DashboardView.ViewModel(repository: repository)
        await model.loadData()
        #expect(model.errors[.sales] == nil)
        #expect(!model.loadedSections.contains(.sales))
        #expect(!model.isLoading)
        repository.salesResult = .success([])
        await model.retry(.sales)
        #expect(model.loadedSections.contains(.sales))
    }

    @Test
    func revisitingDashboardResumesOnlyCancelledSections() async {
        let repository = DashboardRecoveryRepository()
        repository.salesResult = .failure(CancellationError())
        let model = DashboardView.ViewModel(repository: repository)
        await model.loadData()
        repository.salesResult = .success([])
        await model.loadData()
        #expect(model.loadedSections.contains(.sales))
        #expect(repository.requests == [2, 1, 1, 1])
    }

    @Test
    func returningToDashboardWaitsForCancelledLoadToFinish() async {
        let repository = DashboardRecoveryRepository()
        let gate = RecoveryGate()
        repository.salesGate = gate
        repository.salesResult = .failure(CancellationError())
        let model = DashboardView.ViewModel(repository: repository)
        let original = Task { await model.loadData() }
        await gate.waitUntilStarted()
        repository.salesResult = .success([])
        let cleanup = Task { await gate.open() }
        await model.loadData()
        await cleanup.value
        await original.value
        #expect(model.loadedSections.contains(.sales))
        #expect(repository.requests == [2, 1, 1, 1])
        #expect(!model.isLoading)
    }

    @Test
    func failedSectionCanRetryWhileUnrelatedSalesAreStillLoading() async throws {
        let repository = DashboardRecoveryRepository()
        let gate = RecoveryGate()
        let stockRequest = RecoveryNotice()
        repository.salesGate = gate
        repository.stockResult = .failure(URLError(.timedOut))
        repository.onStockRequest = { stockRequest.signal() }
        let model = DashboardView.ViewModel(repository: repository)
        let load = Task { await model.loadData() }
        await stockRequest.wait()
        await gate.waitUntilStarted()
        #expect(model.errors[.stock] != nil)
        repository.stockResult = .success([])
        await model.retry(.stock)
        #expect(model.errors[.stock] == nil)
        #expect(model.loadedSections.contains(.stock))
        await gate.open()
        await load.value
    }

    @Test
    func dashboardIgnoresDuplicateSectionRetries() async {
        let repository = DashboardRecoveryRepository()
        repository.salesResult = .failure(URLError(.timedOut))
        let model = DashboardView.ViewModel(repository: repository)
        await model.loadData()
        let gate = RecoveryGate()
        repository.salesGate = gate
        repository.salesResult = .success([])
        let first = Task { await model.retry(.sales) }
        await gate.waitUntilStarted()
        #expect(model.isLoading)
        await model.retry(.sales)
        await model.loadData(forceRefresh: true)
        await gate.open()
        await first.value
        #expect(repository.requests == [2, 1, 1, 1])
        #expect(!model.isLoading)
    }

}

@MainActor
private final class DashboardRecoveryRepository: DashboardRepository {
    var salesGate: RecoveryGate?
    var onStockRequest: (() -> Void)?
    var salesResult: Result<[WeeklySalesEntry], Error> = .success([
        WeeklySalesEntry(salesDate: Date(timeIntervalSince1970: 0), totalSales: 100, totalProfit: 20)
    ])
    var performanceResult: Result<[ProductPerformanceEntry], Error> = .success([
        ProductPerformanceEntry(productId: 7, productName: "Bike", unitsSold: 3, unitsInStock: 10)
    ])
    var stockResult: Result<[LowStockEntry], Error> = .success([
        LowStockEntry(productId: 8, productName: "Helmet", stockLevel: 1, reorderPoint: 5, safetyStockLevel: 10)
    ])
    var shiftsResult: Result<[ShiftEntry], Error> = .success([
        ShiftEntry(employeeId: 9, firstName: "Jordan", middleName: nil, lastName: "Lee", suffix: nil, shift: "Day")
    ])
    private(set) var requests = [0, 0, 0, 0]

    func getWeeklySales() async throws -> [WeeklySalesEntry] {
        requests[0] += 1
        let result = salesResult
        if let salesGate {
            self.salesGate = nil
            await salesGate.wait()
        }
        return try result.get()
    }

    func getProductPerformance() async throws -> [ProductPerformanceEntry] {
        requests[1] += 1
        return try performanceResult.get()
    }

    func getLowStock() async throws -> [LowStockEntry] {
        requests[2] += 1
        onStockRequest?()
        return try stockResult.get()
    }

    func getShifts() async throws -> [ShiftEntry] {
        requests[3] += 1
        return try shiftsResult.get()
    }
}

@MainActor
private final class RecoveryNotice {
    private var signalled = false
    private var waiter: CheckedContinuation<Void, Never>?

    func signal() {
        signalled = true
        waiter?.resume()
        waiter = nil
    }

    func wait() async {
        if signalled { return }
        await withCheckedContinuation { waiter = $0 }
    }
}
