//
//  DashboardRepository.swift
//  AdventureWorksMobile
//
//  Created by user302023 on 10/1/26.
//

protocol DashboardRepository {
    func getWeeklySales() async throws -> [WeeklySalesEntry]
    func getProductPerformance() async throws -> [ProductPerformanceEntry]
    func getLowStock() async throws -> [LowStockEntry]
    func getShifts() async throws -> [ShiftEntry]
}
