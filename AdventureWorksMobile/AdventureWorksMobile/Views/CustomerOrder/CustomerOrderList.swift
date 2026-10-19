//
//  CustomerOrderList.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 9/20/26.
//

import SwiftUI

/// Lists every customer order. Each row shows the order number on the
/// left and the order total on the right. Tapping a row opens the
/// order details page.
struct CustomerOrderList: View {

    @State private var viewModel = ViewModel()
    @State private var isSearchVisible = false
    @Environment(\.customerOrderRepository) private var repository

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ListHeader(title: "Orders",
                           errorMessage: viewModel.errorMessage)

                VStack(spacing: 4) {
                    HStack {
                        Button {
                            isSearchVisible.toggle()
                        } label: {
                            Label(isSearchVisible ? "Hide search" :
                                    (viewModel.searchText.isEmpty ? "Search" : "Search: \(viewModel.searchText)"),
                                  systemImage: "magnifyingglass")
                        }
                        .accessibilityIdentifier("orderSearchButton")
                        Spacer()
                        Button("Clear", action: viewModel.clearCriteria)
                            .disabled(!viewModel.hasActiveCriteria)
                            .accessibilityIdentifier("clearCriteriaButton")
                    }
                    .padding(.vertical, 4)

                    if isSearchVisible {
                        TextField("Search customer or order number", text: $viewModel.searchText)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .accessibilityIdentifier("orderSearchField")
                    }
                    HStack {
                        Text("Sort by")
                            .font(.subheadline)
                        Spacer()
                        Picker("Sort by", selection: $viewModel.sortOption) {
                            ForEach(SortOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                        .accessibilityIdentifier("orderSortPicker")
                    }
                }
                .padding(.horizontal)

                List {
                    ForEach(viewModel.orders.shown) { order in
                        NavigationLink {
                            CustomerOrderDetails(order: order)
                        } label: {
                            VStack {
                                HStack {
                                    Text(verbatim: "Order #\(order.orderNumber)")
                                    Spacer()
                                    Text(order.total, format: .currency(code: "USD"))
                                        .foregroundStyle(.secondary)
                                }
                                Text(order.customerName)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundStyle(.secondary)
                                HStack {
                                    Text("Ordered:")
                                    Spacer()
                                    DateText(date: order.orderDate)
                                }
                                .foregroundStyle(.secondary)
                            }
                        }
                    }

                    // Reached the last loaded order: show the next page.
                    if viewModel.orders.hasMore {
                        LoadMoreRow { viewModel.orders.loadMore() }
                    }
                }
                .overlay {
                    if !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                       viewModel.orders.all.isEmpty {
                        ContentUnavailableView.search(text: viewModel.searchText)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            // The title is drawn by ListHeader so it stays put while the list
            // scrolls. The system nav bar is hidden on this screen only.
            // navigationTitle is still set so the back button on the
            // details page reads "Orders".
            .navigationTitle("Orders")
            .toolbar(.hidden, for: .navigationBar)
            .task { await viewModel.loadData(repository: repository) }
        }
    }
}

/// One product line inside an order.
///
/// This is a plain copy of the values, not the Core Data object.
/// When the repository refreshes its cache, it deletes the old Core Data
/// objects. A view still holding one of those would suddenly show empty
/// values. Copying the values here keeps the details page safe.
struct OrderLine: Identifiable, Hashable {
    let id: Int64
    let productName: String?
    let orderQty: Int64
    let unitPrice: Double
    let lineTotal: Double

    init(_ order: CustomerOrder) {
        id = order.id
        productName = order.productName
        orderQty = order.orderQty
        unitPrice = order.unitPrice
        lineTotal = order.lineTotal
    }
}

/// One order made up of its line items.
///
/// The API returns one row per product in an order. Every row repeats
/// the shared order info (order number, dates, customer). This struct
/// groups those rows back into a single order and copies the values out
/// of Core Data (see OrderLine for why).
struct OrderGroup: Identifiable, Hashable {
    let orderNumber: Int64
    let orderDate: String?
    let sortDate: Date?
    let shipDate: String?
    let customerId: Int64?
    let customerName: String
    let lines: [OrderLine]

    var id: Int64 { orderNumber }

    init(orderNumber: Int64, rows: [CustomerOrder]) {
        let sorted = rows.sorted { $0.id < $1.id }
        // Shared order info. Every row has the same values, so read the first one.
        let first = sorted.first

        self.orderNumber = orderNumber
        self.sortDate = DateText.parseDate(first?.orderDate)
        self.orderDate = first?.orderDate
        self.shipDate = first?.shipDate
        self.customerId = first?.customerId
        self.customerName = [first?.firstName, first?.lastName]
            .compactMap { $0 }
            .joined(separator: " ")
        self.lines = sorted.map(OrderLine.init)
    }

    // Summary numbers
    var total: Double { lines.reduce(0) { $0 + $1.lineTotal } }
    var totalUnits: Int64 { lines.reduce(0) { $0 + $1.orderQty } }
    var productCount: Int { lines.count }
}

extension CustomerOrderList {

    enum SortOption: String, CaseIterable, Identifiable {
        case number = "Order number (ascending)"
        case newest = "Newest first"
        case oldest = "Oldest first"

        var id: String { rawValue }
    }

    @MainActor
    @Observable
    class ViewModel {
        /// Every order, revealed a page at a time as the user scrolls.
        var orders = PagedItems<OrderGroup>(pageSize: 25)
        var source: CachedDataSource = .notcached
        var errorMessage: String = ""

        private var allOrders: [OrderGroup] = []
        var searchText = "" { didSet { applyCriteria(resetPage: true) } }
        var sortOption: SortOption = .number { didSet { applyCriteria(resetPage: true) } }

        var hasActiveCriteria: Bool { !searchText.isEmpty || sortOption != .number }

        func clearCriteria() {
            searchText = ""
            sortOption = .number
        }

        func setOrders(_ values: [OrderGroup]) {
            allOrders = values
            applyCriteria(resetPage: false)
        }

        private func applyCriteria(resetPage: Bool) {
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let matches = allOrders.filter { order in
                query.isEmpty || order.customerName.localizedStandardContains(query)
                    || String(order.orderNumber).contains(query)
            }
            let sorted = matches.sorted { left, right in
                if sortOption != .number {
                    switch (left.sortDate, right.sortDate) {
                    case let (leftDate?, rightDate?) where leftDate != rightDate:
                        return sortOption == .newest ? leftDate > rightDate : leftDate < rightDate
                    case (_?, nil): return true
                    case (nil, _?): return false
                    default: break
                    }
                }
                return left.orderNumber < right.orderNumber
            }
            orders.replace(with: sorted, resetPage: resetPage)
        }

        func loadData(repository: (any TieredCacheRepositoryProtocol<CustomerOrder>)?) async {
            guard let repository = repository else { return }

            do {
                let (rows, source) = try await repository.getAll()
                self.source = source

                // Group the API rows into orders once, here, instead of on
                // every redraw.
                let grouped = Dictionary(grouping: rows, by: \.orderNumber)
                    .map { OrderGroup(orderNumber: $0.key, rows: $0.value) }
                setOrders(grouped)

                print("Loaded \(rows.count) lines in \(grouped.count) orders from \(source)")
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview { CustomerOrderList() }
