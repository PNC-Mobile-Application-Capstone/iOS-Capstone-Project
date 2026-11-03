//
//  CustomerOrderDetailsView.swift
//  AdventureWorksMobile
//

import SwiftUI

/// One order: shared info on top, a row per product, then a summary.
struct CustomerOrderDetails: View {

    @Environment(\.productRepository) private var productRepository

    let order: OrderGroup

    /// Products keyed by name, since order lines only carry the product name.
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
        // Wrap in String so the order number shows without a comma.
        .navigationTitle(String("Order #\(order.orderNumber)"))
        .task { await loadProducts() }
    }

    private func loadProducts() async {
        guard let productRepository else { return }
        do {
            let (products, _) = try await productRepository.getAll()
            // Build a name-to-product lookup. Skip products with no name and keep the first duplicate.
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
