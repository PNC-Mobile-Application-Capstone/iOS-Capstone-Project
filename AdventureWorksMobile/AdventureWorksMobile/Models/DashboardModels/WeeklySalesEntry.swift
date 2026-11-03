//
//  WeeklySalesEntry.swift
//  AdventureWorksMobile
//

import Foundation

struct WeeklySalesEntry: Identifiable, Codable {
    let salesDate: Date
    let totalSales: Double
    let totalProfit: Double

    var id: Date { salesDate }
}
