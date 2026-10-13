//
//  CustomerOrderDetailsView.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 9/25/26.
//

import SwiftUI

/// Details for one order.
///
/// Top: shared order info (dates, customer).
/// Middle: one row per product. Tapping a row opens that product's details.
/// Bottom: order summary (product count, units, total).
struct CustomerOrderDetails: View {

    @Environment(\.productRepository) private var productRepository

    let order: OrderGroup

    /// Products keyed by name. Order lines only carry the product name,
    /// so we match on name to find the full Product for the details page.
    @State private var productsByName: [String: Product] = [:]

    var body: some View {
        List {
            Section("Order Info") {
                LabeledContent("Order Date") { DateText(date: order.orderDate) }
                LabeledContent("Ship Date") { DateText(date: order.shipDate) }
                LabeledContent("Customer", value: order.customerName.isEmpty ? "--" : order.customerName)
                if let customerId = order.customerId {
                    LabeledContent("Customer ID", value: "\(customerId)")
                }
            }

            Section("Products") {
                ForEach(order.lines) { line in
                    if let product = productsByName[line.productName ?? ""] {
                        NavigationLink {
                            ProductDetails(product: product)
                        } label: {
                            OrderLineRow(line: line)
                        }
                    } else {
                        // No matching product yet (still loading, or not found)
                        OrderLineRow(line: line)
                    }
                }
            }

            Section("Summary") {
                LabeledContent("Products", value: "\(order.productCount)")
                LabeledContent("Total Units", value: "\(order.totalUnits)")
                LabeledContent("Order Total") {
                    Text(order.total, format: .currency(code: "USD"))
                        .fontWeight(.semibold)
                }
            }
        }
        .navigationTitle(String("Order #\(order.orderNumber)"))
        .task { await loadProducts() }
    }

    private func loadProducts() async {
        guard let productRepository else { return }
        do {
            let (products, _) = try await productRepository.getAll()
            productsByName = Dictionary(
                products.compactMap { p in p.name.map { ($0, p) } },
                uniquingKeysWith: { first, _ in first }
            )
        } catch {
            print("Product lookup failed: \(error)")
        }
    }
}

/// One product line inside an order.
private struct OrderLineRow: View {
    let line: OrderLine

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(line.productName ?? "--")
                Text("\(line.orderQty) x \(line.unitPrice, format: .currency(code: "USD"))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(line.lineTotal, format: .currency(code: "USD"))
        }
    }
}

#Preview {
    CustomerOrderList()
}
