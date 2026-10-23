//
//  StockLevel.swift
//  AdventureWorksMobile
//

import Foundation


// Stock status and color band for one item. nonisolated so any thread can use it.
nonisolated struct StockLevel: Equatable {
    let quantity: Int64
    let reorderPoint: Int64
    let safetyStockLevel: Int64

    /// Quantity as a fraction of safety stock (0.24 means 24%). Nil when safety stock is 0.
    var fractionOfSafetyStock: Double? {
        guard safetyStockLevel > 0 else { return nil }
        return Double(quantity) / Double(safetyStockLevel)
    }

    /// True when the item is at or below its reorder point, as the requirement asks.
    var needsReorder: Bool { quantity <= reorderPoint }

    // Checked worst to best, so the first match wins.
    var status: Status {
        if quantity <= 0 { return .outOfStock }
        if let fraction = fractionOfSafetyStock, fraction <= 0.25 { return .critical }
        if needsReorder { return .reorder }
        if quantity < safetyStockLevel { return .low }
        return .inStock
    }

    /// Color band from the team sketch. Each band includes its top edge, so exactly 75% is yellow.
    var band: Band {
        guard let fraction = fractionOfSafetyStock else {
            return quantity <= 0 ? .red : (needsReorder ? .orange : .blue)
        }
        switch fraction {
        // "...0.25" means up to and including 0.25. "..<1.00" means below 1.00.
        case ...0.25: return .red
        case ...0.50: return .orange
        case ...0.75: return .yellow
        case ..<1.00: return .green
        default:      return .blue
        }
    }

    /// Sorts worst first: by status, then by how far below safety stock.
    static func worstFirst(_ left: StockLevel, _ right: StockLevel) -> Bool {
        if left.status != right.status { return left.status < right.status }
        return left.sortFraction < right.sortFraction
    }

    // With no safety stock set, empty items sort first and the rest sort last.
    private var sortFraction: Double {
        fractionOfSafetyStock ?? (quantity <= 0 ? 0 : .greatestFiniteMagnitude)
    }

    /// Ordered from worst to best, so `<` means "more urgent".
    nonisolated enum Status: Int, Comparable, CaseIterable {
        case outOfStock, critical, reorder, low, inStock

        // Comparable needs <. Earlier cases have lower raw values, so they count as worse.
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

        /// Each status has its own icon, so color is never the only signal.
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
