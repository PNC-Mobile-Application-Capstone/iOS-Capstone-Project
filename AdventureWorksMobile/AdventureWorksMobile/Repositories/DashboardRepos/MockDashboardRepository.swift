//
//  MockDashboardRepository.swift
//  AdventureWorksMobile
//
//  Created by user302023 on 10/1/26.
//

import Foundation

class MockDashboardRepository: DashboardRepository {
    
    func getWeeklySales() async throws -> [WeeklySalesEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let amounts: [(sales: Double, profit: Double)] = [
            (18_400, 5_520), (22_100, 6_630), (15_800, 4_740),
            (29_600, 8_880), (34_200, 10_260), (12_300, 3_690), (9_100, 2_730)
        ]
        return amounts.enumerated().map { offset, pair in
            let date = calendar.date(byAdding: .day, value: -(6 - offset), to: today)!
            return WeeklySalesEntry(salesDate: date, totalSales: pair.sales, totalProfit: pair.profit)
        }
    }
    
    func getProductPerformance() async throws -> [ProductPerformanceEntry] {
        [
            ProductPerformanceEntry(productId: 1, productName: "Road-150 Red, 62", unitsSold: 42, unitsInStock: 12),
            ProductPerformanceEntry(productId: 2, productName: "Mountain-200 Black, 38", unitsSold: 31, unitsInStock: 34),
            ProductPerformanceEntry(productId: 3, productName: "Water Bottle – 30 oz.", unitsSold: 28, unitsInStock: 312),
            ProductPerformanceEntry(productId: 4, productName: "Sport-100 Helmet, Red", unitsSold: 4, unitsInStock: 58),
            ProductPerformanceEntry(productId: 5, productName: "AWC Logo Cap", unitsSold: 2, unitsInStock: 91)
        ]
    }
    
    func getLowStock() async throws -> [LowStockEntry] {
        [
            LowStockEntry(productId: 3, productName: "Mountain-100 Black, 38", stockLevel: 7, reorderPoint: 20),
            LowStockEntry(productId: 6, productName: "Half-Finger Gloves, S", stockLevel: 6, reorderPoint: 25),
            LowStockEntry(productId: 9, productName: "Carbon Fiber Racket", stockLevel: 11, reorderPoint: 15)
        ]
    }
    
    func getShifts() async throws -> [ShiftEntry] {
        [
            ShiftEntry(employeeId: 1, firstName: "Jordan", middleName: "", lastName: "Lee", suffix: "", shift: "8am–5pm"),
            ShiftEntry(employeeId: 2, firstName: "Priya", middleName: "R", lastName: "Nair", suffix: "", shift: "8am–5pm"),
            ShiftEntry(employeeId: 4, firstName: "Sofia", middleName: "", lastName: "Delgado", suffix: "", shift: "8am–5pm"),
            ShiftEntry(employeeId: 3, firstName: "Marcus", middleName: "T", lastName: "Webb", suffix: "", shift: "2pm–11pm"),
            ShiftEntry(employeeId: 5, firstName: "Tyler", middleName: "", lastName: "Chen", suffix: "Jr", shift: "9am–6pm")
        ]
    }
    
}
