//
//  LowStockEntry.swift
//  AdventureWorksMobile
//

import Foundation

struct LowStockEntry: Identifiable, Codable {
    let productId: Int
    let productName: String
    let stockLevel: Int
    let reorderPoint: Int

    var id: Int { productId }
    
    // Critical when stock is below half the reorder point.
    var isCritical: Bool {
        reorderPoint > 0 && stockLevel < reorderPoint / 2
    }
}
