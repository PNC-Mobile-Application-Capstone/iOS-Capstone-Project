//
//  WeeklySalesEntry.swift
//  AdventureWorksMobile
//
//  Created by user302023 on 10/1/26.
//

import Foundation

struct WeeklySalesEntry: Identifiable, Codable {
    let salesDate: Date
    let totalSales: Double
    let totalProfit: Double

    var id: Date { salesDate }
}
