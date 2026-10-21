//
//  DashboardRepository.swift
//  AdventureWorksMobile
//
//  Created by user302023 on 10/1/26.
//

// The four dashboard calls. The remote and mock repositories both follow this.
protocol DashboardRepository {
    func getWeeklySales() async throws -> [WeeklySalesEntry]
    func getProductPerformance() async throws -> [ProductPerformanceEntry]
    func getLowStock() async throws -> [LowStockEntry]
    func getShifts() async throws -> [ShiftEntry]
}
