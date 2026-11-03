//
//  DashboardRepository.swift
//  AdventureWorksMobile
//

// The four dashboard calls. The remote and mock repositories both follow this.
protocol DashboardRepository {
    func getWeeklySales() async throws -> [WeeklySalesEntry]
    func getProductPerformance() async throws -> [ProductPerformanceEntry]
    func getLowStock() async throws -> [LowStockEntry]
    func getShifts() async throws -> [ShiftEntry]
}
