//
//  Inventory+Display.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 10/18/26.
//

import Foundation

// Display text for an Inventory row, with placeholders for missing values.
extension Inventory {

    var stockLevel: StockLevel {
        StockLevel(quantity: quantity,
                   reorderPoint: reorderPoint,
                   safetyStockLevel: safetyStockLevel)
    }

    var displayName: String {
        let name = productName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "Unnamed product" : name
    }

    var displayProductNumber: String {
        let number = productNumber?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return number.isEmpty ? "No product number" : number
    }

    var displayLocation: String {
        let name = locationName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "Location \(locationId)" : name
    }

    /// "Shelf A, Bin 3", "Shelf A", "Bin 3", or "No shelf assigned".
    var displayShelfBin: String {
        let shelfText = shelf?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        var parts: [String] = []
        if !shelfText.isEmpty, shelfText.uppercased() != "N/A" { parts.append("Shelf \(shelfText)") }
        if let bin { parts.append("Bin \(bin.int64Value)") }
        return parts.isEmpty ? "No shelf assigned" : parts.joined(separator: ", ")
    }

    /// VoiceOver reads for the whole row
    var accessibilitySummary: String {
        "\(displayName). \(displayLocation), \(displayShelfBin). "
            + "Quantity \(quantity), reorder at \(reorderPoint). \(stockLevel.status.label)."
    }
}
