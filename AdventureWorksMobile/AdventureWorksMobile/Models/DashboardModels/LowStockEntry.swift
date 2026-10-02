//
//  LowStockEntry.swift
//  AdventureWorksMobile
//
//  Created by user302023 on 10/1/26.
//

import Foundation

struct LowStockEntry: Identifiable, Codable {
    let productId: Int
    let productName: String
    let stockLevel: Int
    let reorderPoint: Int

    var id: Int { productId }
    
    var isCritical: Bool {
        reorderPoint > 0 && stockLevel < reorderPoint / 2
    }
}
