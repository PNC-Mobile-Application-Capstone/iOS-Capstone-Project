//
//  ProductList.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 9/20/26.
//

import SwiftUI

struct CustomerOrderList: View {

    @State private var viewModel = ViewModel()
    @Environment(\.customerOrderRepository) private var repository

    var body: some View {
        NavigationStack {
            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage).font(.title)
            }

            switch viewModel.source {
            case .memory:       Text("cached in memory")
            case .disk:         Text("local disk cache")
            case .notcached:    Text("fresh api data")
            case .staleDisk:    Text("stale disk")
            }

            List(viewModel.groupedOrders) { group in
                Section {
                    ForEach(group.lines) { line in
                        NavigationLink {
                            CustomerOrderDetails(customerOrder: line)
                        } label: {
                            HStack {
                                Text(line.productName ?? "--")
                                Spacer()
                                Text("x\(line.orderQty)")
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Order #\(group.orderNumber)")
                        Spacer()
                        Text(group.total, format: .currency(code: "USD"))
                    }
                }
            }
            .task { await viewModel.loadData(repository: repository) }
        }
    }
}

// One order made up of its line items
struct OrderGroup: Identifiable {
    let orderNumber: Int64
    let lines: [CustomerOrder]

    var id: Int64 { orderNumber }
    var total: Double { lines.reduce(0) { $0 + $1.lineTotal } }
    var orderDate: String? { lines.first?.orderDate }
}

extension CustomerOrderList {

    @Observable
    class ViewModel {
        var orders: [CustomerOrder] = []
        var source: CachedDataSource = .notcached
        var errorMessage: String = ""

        // Recomputed whenever `orders` changes
        var groupedOrders: [OrderGroup] {
            Dictionary(grouping: orders, by: \.orderNumber)
                .map { OrderGroup(orderNumber: $0.key, lines: $0.value) }
                .sorted { $0.orderNumber < $1.orderNumber }
        }

        func loadData(repository: (any TieredCacheRepositoryProtocol<CustomerOrder>)?) async {
            guard let repository = repository else { return }

            do {
                (orders, source) = try await repository.getAll()
                print("Loaded \(orders.count) lines in \(groupedOrders.count) orders from \(source)")
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview { CustomerOrderList() }
