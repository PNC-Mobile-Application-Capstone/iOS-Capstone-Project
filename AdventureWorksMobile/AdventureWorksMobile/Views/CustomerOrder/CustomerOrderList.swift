//
//  CustomerOrderList.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 9/20/26.
//

import SwiftUI

/// Lists every order with its number, total, customer, and date. Tap a row for details.
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
                            // Button text is "Hide search", "Search", or "Search: <text>".
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
                        // $ makes a two-way binding, so typing updates searchText.
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
                        // Each option's tag is the value the picker writes to sortOption.
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
                                    // verbatim shows the text as-is, so the number has no comma.
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
                // Show a "no results" view when a search matches nothing.
                .overlay {
                    if !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                       viewModel.orders.all.isEmpty {
                        ContentUnavailableView.search(text: viewModel.searchText)
                    }
                }
                .refreshable {
                    await viewModel.loadData(repository: repository, forceRefresh: true)
                }
            }
            .background(Color(.systemGroupedBackground))
            // ListHeader draws the title so it stays put. navigationTitle still names the back button.
            .navigationTitle("Orders")
            .toolbar(.hidden, for: .navigationBar)
            // Load the data when the screen appears.
            .task { await viewModel.loadData(repository: repository) }
        }
    }
}

/// A plain copy of one order line, so a cache refresh can't empty a view that holds it.
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

/// One order rebuilt from its API rows, with values copied out of Core Data.
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
        // Sort the rows by line ID so the order is stable.
        let sorted = rows.sorted { $0.id < $1.id }
        // Shared order info. Every row has the same values, so read the first one.
        let first = sorted.first

        self.orderNumber = orderNumber
        self.sortDate = DateText.parseDate(first?.orderDate)
        self.orderDate = first?.orderDate
        self.shipDate = first?.shipDate
        self.customerId = first?.customerId
        // Join first and last name, skipping any nil part.
        self.customerName = [first?.firstName, first?.lastName]
            .compactMap { $0 }
            .joined(separator: " ")
        self.lines = sorted.map(OrderLine.init)
    }

    // Summary numbers. reduce adds up one field across every line.
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

    // @Observable redraws a view only when a property it reads changes.
    @MainActor
    @Observable
    class ViewModel {
        /// Every order, revealed a page at a time as the user scrolls.
        var orders = PagedItems<OrderGroup>(pageSize: 25)
        var source: CachedDataSource = .notcached
        var errorMessage: String = ""

        private var allOrders: [OrderGroup] = []
        // didSet reruns the search and sort whenever these change.
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

        // Filter by search text, sort, then hand the result to the pager.
        private func applyCriteria(resetPage: Bool) {
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let matches = allOrders.filter { order in
                query.isEmpty || order.customerName.localizedStandardContains(query)
                    || String(order.orderNumber).contains(query)
            }
            let sorted = matches.sorted { left, right in
                if sortOption != .number {
                    // Compare the dates. Orders with no date go last.
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

        func loadData(repository: (any TieredCacheRepositoryProtocol<CustomerOrder>)?, forceRefresh: Bool=false) async {
            guard let repository = repository else { return }

            do {
                let (rows, source) = try await repository.getAll(forceRefresh: forceRefresh)
                self.source = source

                // Group the API rows into orders once, here, instead of on every redraw.
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
