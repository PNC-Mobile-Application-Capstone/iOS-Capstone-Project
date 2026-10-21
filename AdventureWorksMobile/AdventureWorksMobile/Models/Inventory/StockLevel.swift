//
//  StockLevel.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 10/20/26.
//

import Foundation


nonisolated struct StockLevel: Equatable {
    let quantity: Int64
    let reorderPoint: Int64
    let safetyStockLevel: Int64

    /// Quantity as a fraction of safety stock. 0.24 means 24%.
    /// Nil when safety stock is 0 or less, so we never divide by zero.
    var fractionOfSafetyStock: Double? {
        guard safetyStockLevel > 0 else { return nil }
        return Double(quantity) / Double(safetyStockLevel)
    }

    /// True when the item is at or below its reorder point.
    /// This is the flag the requirement asks for.
    var needsReorder: Bool { quantity <= reorderPoint }

    var status: Status {
        if quantity <= 0 { return .outOfStock }
        if let fraction = fractionOfSafetyStock, fraction <= 0.25 { return .critical }
        if needsReorder { return .reorder }
        if quantity < safetyStockLevel { return .low }
        return .inStock
    }

    /// Color band from the team sketch. Each band includes its top edge,
    /// so exactly 75% is yellow, matching "at or below reorder point".
    /// Color is extra. It never carries meaning alone, because every
    /// status also has its own icon and text.
    var band: Band {
        guard let fraction = fractionOfSafetyStock else {
            return quantity <= 0 ? .red : (needsReorder ? .orange : .blue)
        }
        switch fraction {
        case ...0.25: return .red
        case ...0.50: return .orange
        case ...0.75: return .yellow
        case ..<1.00: return .green
        default:      return .blue
        }
    }

    /// Worst first. Used to sort rows and locations.
    /// Status first, then how far below safety stock, lowest first.
    static func worstFirst(_ left: StockLevel, _ right: StockLevel) -> Bool {
        if left.status != right.status { return left.status < right.status }
        return left.sortFraction < right.sortFraction
    }

    private var sortFraction: Double {
        fractionOfSafetyStock ?? (quantity <= 0 ? 0 : .greatestFiniteMagnitude)
    }

    /// Ordered from worst to best, so `<` means "more urgent".
    nonisolated enum Status: Int, Comparable, CaseIterable {
        case outOfStock, critical, reorder, low, inStock

        static func < (left: Status, right: Status) -> Bool {
            left.rawValue < right.rawValue
        }

        var label: String {
            switch self {
            case .outOfStock: "Out of stock"
            case .critical:   "Critical"
            case .reorder:    "Reorder"
            case .low:        "Low"
            case .inStock:    "In stock"
            }
        }

        /// Each status has its own shape, so users who cannot tell the
        /// colors apart can still tell the statuses apart.
        var systemImage: String {
            switch self {
            case .outOfStock: "xmark.octagon.fill"
            case .critical:   "exclamationmark.octagon.fill"
            case .reorder:    "exclamationmark.triangle.fill"
            case .low:        "arrow.down.circle.fill"
            case .inStock:    "checkmark.circle.fill"
            }
        }

        /// At or below the reorder point. These get the glow.
        var isUrgent: Bool { self <= .reorder }

        /// The two worst. These also pulse, unless Reduce Motion is on.
        var pulses: Bool { self <= .critical }
    }

    nonisolated enum Band: CaseIterable {
        case red, orange, yellow, green, blue
    }
}
