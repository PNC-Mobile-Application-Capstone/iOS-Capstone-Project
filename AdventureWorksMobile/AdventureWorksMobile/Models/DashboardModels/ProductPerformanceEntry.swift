//
//  ProductPerformanceEntry.swift
//  AdventureWorksMobile
//
//  Created by user302023 on 10/1/26.
//

import Foundation

struct ProductPerformanceEntry: Identifiable, Codable {
    let productId: Int
    let productName: String
    let unitsSold: Int
    let unitsInStock: Int

    var id: Int { productId }
}
