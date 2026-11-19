//
//  InventoryRowViews.swift
//  AdventureWorksMobile
//
//  The pieces of the Inventory screen: the status icon, the location
//  header, the product row, and the product details.
//

import SwiftUI

// Maps each band to a SwiftUI color, so the model doesn't need SwiftUI.
extension StockLevel.Band {
    var color: Color {
        switch self {
        case .red:    .red
        case .orange: .orange
        case .yellow: .yellow
        case .green:  .green
        case .blue:   .blue
        }
    }
}

/// Header for one location section.
struct LocationHeader: View {
    let location: LocationGroup
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var itemText: String {
        location.lines.count == 1 ? "1 item" : "\(location.lines.count) items"
    }

    private var reorderText: String {
        location.needsReorderCount == 1 ? "1 needs reorder" : "\(location.needsReorderCount) need reorder"
    }

    private var accessibilityText: String {
        var text = "\(location.name), Location \(location.locationId), \(itemText)."
        if location.needsReorderCount > 0 {
            text += " \(reorderText)."
        }
        return text
    }

    var body: some View {
        let isLarge = dynamicTypeSize.isAccessibilitySize
        let layout = isLarge
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline))

        layout {
            VStack(alignment: .leading, spacing: 2) {
                Text(location.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(verbatim: "Location \(location.locationId) · \(itemText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !isLarge {
                Spacer()
            }
            if location.needsReorderCount > 0 {
                // Orange icon, normal text color so it stays easy to read.
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(reorderText)
                        .foregroundStyle(.primary)
                }
                .font(.caption.weight(.semibold))
            }
        }
        // Keep normal casing, and have VoiceOver read the header as one item.
        .textCase(nil)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }
}

/// One product at one location
struct InventoryLineRow: View {
    let line: InventoryLine
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let level = line.stockLevel
        let isLarge = dynamicTypeSize.isAccessibilitySize
        // Stack at large text sizes, side by side otherwise. AnyLayout lets one variable hold either.
        let layout = isLarge
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 12))

        layout {
            HStack(alignment: .top, spacing: 12) {
                StockStatusIcon(level: level)
                VStack(alignment: .leading, spacing: 2) {
                    Text(line.name)
                        .font(.body)
                    Text(level.status.label)
                        .font(.subheadline.weight(.semibold))
                    Text(verbatim: "\(line.location) · \(line.shelfBin)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if !isLarge {
                Spacer(minLength: 8)
            }

            VStack(alignment: isLarge ? .leading : .trailing, spacing: 2) {
                Text(verbatim: "Qty \(line.quantity)")
                    .font(.headline)
                    .monospacedDigit()
                Text(verbatim: "Reorder at \(line.reorderPoint)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        // VoiceOver reads one summary instead of each piece.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(line.accessibilitySummary)
    }
}

/// Extra details shown when the user opens a product row.
struct InventoryLineDetails: View {
    let line: InventoryLine

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            detailRow("Product number", value: line.productNumberText)
            detailRow("Location", value: "\(line.location) (ID \(line.locationId))")
            detailRow("Shelf and bin", value: line.shelfBin)
            detailRow("Quantity", value: line.quantity.formatted())
            detailRow("Reorder point", value: line.reorderPoint.formatted())
            detailRow("Safety stock", value: line.safetyStockLevel.formatted())
            detailRow("Stock level", value: line.percentOfSafetyText)
        }
        .font(.subheadline)
        .accessibilityElement(children: .contain)
    }

    private func detailRow(_ label: String, value: String) -> some View {
        LabeledContent(label, value: value)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(label), \(value)")
    }
}
