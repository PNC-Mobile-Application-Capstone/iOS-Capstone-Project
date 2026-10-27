//
//  LowStockEntry.swift
//  AdventureWorksMobile
//

import Foundation

struct LowStockEntry: Identifiable, Codable {
    let productId: Int64
    let productName: String
    let stockLevel: Int64
    let reorderPoint: Int64
    let safetyStockLevel: Int64?
    var id: Int64 { productId }
    // Critical when stock is below half the reorder point.
    var isCritical: Bool {
        reorderPoint > 0 && stockLevel < reorderPoint / 2
    }
    
    init(productId: Int64, productName: String ,stockLevel: Int64 ,reorderPoint: Int64, safetyStockLevel: Int64?) {
        self.productId = productId
        self.productName = productName
        self.stockLevel = stockLevel
        self.reorderPoint = reorderPoint
        self.safetyStockLevel = safetyStockLevel
    }
}
