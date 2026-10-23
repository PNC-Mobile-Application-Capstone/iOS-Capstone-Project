//
//  ProductPerformanceEntry.swift
//  AdventureWorksMobile
//

import Foundation

struct ProductPerformanceEntry: Identifiable, Codable {
    let productId: Int
    let productName: String
    let unitsSold: Int
    let unitsInStock: Int

    var id: Int { productId }
}
