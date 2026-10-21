//
//  InventoryRowViews.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 10/18/26.
//
//  The pieces of the Inventory screen: the status icon, the location
//  header, the product row, and the product details.
//

import SwiftUI

/// The stock status icon.
struct StockStatusIcon: View {
    let level: StockLevel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let status = level.status
        let color = level.band.color

        Image(systemName: status.systemImage)
            .font(.title3)
            .foregroundStyle(color)
            // Glow when urgent, and pulse when critical unless Reduce Motion is on.
            .shadow(color: status.isUrgent ? color.opacity(0.8) : .clear,
                    radius: status.isUrgent ? 6 : 0)
            .symbolEffect(.pulse, isActive: status.pulses && !reduceMotion)
            .frame(minWidth: 28)
            .accessibilityHidden(true)
    }
}

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

    private var itemText: String {
        location.lines.count == 1 ? "1 item" : "\(location.lines.count) items"
    }

    private var reorderText: String {
        location.needsReorderCount == 1 ? "1 needs reorder" : "\(location.needsReorderCount) need reorder"
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(location.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(verbatim: "Location \(location.locationId) · \(itemText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
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
        .accessibilityElement(children: .combine)
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
            LabeledContent("Product number", value: line.productNumberText)
            LabeledContent("Location", value: "\(line.location) (ID \(line.locationId))")
            LabeledContent("Shelf and bin", value: line.shelfBin)
            LabeledContent("Quantity", value: line.quantity.formatted())
            LabeledContent("Reorder point", value: line.reorderPoint.formatted())
            LabeledContent("Safety stock", value: line.safetyStockLevel.formatted())
            LabeledContent("Stock level", value: line.percentOfSafetyText)
        }
        .font(.subheadline)
        .accessibilityElement(children: .contain)
    }
}
