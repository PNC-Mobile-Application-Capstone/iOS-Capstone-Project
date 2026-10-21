//
//  RemoteDashboardRepository.swift
//  AdventureWorksMobile
//
//  Created by user302023 on 10/14/26.
//

// Loads dashboard data from the API, with one base repository per response type.
@MainActor
class RemoteDashboardRepository: DashboardRepository {
 
    private let weeklySales: RemoteRepositoryBase<WeeklySalesEntry>
    private let productPerformance: RemoteRepositoryBase<ProductPerformanceEntry>
    private let lowStock: RemoteRepositoryBase<LowStockEntry>
    private let shifts: RemoteRepositoryBase<ShiftEntry>
 
    init(authStatus: AuthStatus) {
        weeklySales = RemoteRepositoryBase(authStatus: authStatus)
        productPerformance = RemoteRepositoryBase(authStatus: authStatus)
        lowStock = RemoteRepositoryBase(authStatus: authStatus)
        shifts = RemoteRepositoryBase(authStatus: authStatus)
    }
 
    // GET /api/Dashboard/weekly-sales
    func getWeeklySales() async throws -> [WeeklySalesEntry] {
        try await weeklySales.fetchAll(APIEndpoint.weeklySales.urlString)
    }
 
    // GET /api/Dashboard/best-worst
    func getProductPerformance() async throws -> [ProductPerformanceEntry] {
        try await productPerformance.fetchAll(APIEndpoint.bestWorstProducts.urlString)
    }
 
    // GET /api/Dashboard/low-stock
    func getLowStock() async throws -> [LowStockEntry] {
        try await lowStock.fetchAll(APIEndpoint.lowStock.urlString)
    }
 
    // GET /api/Dashboard/shifts
    func getShifts() async throws -> [ShiftEntry] {
        try await shifts.fetchAll(APIEndpoint.shifts.urlString)
    }
 
}
