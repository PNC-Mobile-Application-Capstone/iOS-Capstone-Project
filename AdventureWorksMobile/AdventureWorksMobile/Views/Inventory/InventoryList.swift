//
//  InventoryList.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 10/18/26.
//

import SwiftUI

/// Lists stock by location
struct InventoryList: View {

    @State private var viewModel = ViewModel()
    @State private var isSearchVisible = false
    @State private var expandedLocations: Set<Int64> = []
    @Environment(\.inventoryRepository) private var repository

    private var searchButtonTitle: String {
        if isSearchVisible {
            return "Hide search"
        }

        if viewModel.searchText.isEmpty {
            return "Search"
        }

        return "Search: \(viewModel.searchText)"
    }

    var body: some View {
        NavigationStack {
            List {
                // Search lives in the first row, so it scrolls away like the rest of the list.
                ListHeader(errorMessage: viewModel.errorMessage) {
                    HStack {
                        Button {
                            isSearchVisible.toggle()
                        } label: {
                            Label(searchButtonTitle, systemImage: "magnifyingglass")
                        }
                        .accessibilityIdentifier("inventorySearchButton")
                        Spacer()
                        Button("Clear", action: viewModel.clearCriteria)
                            .disabled(!viewModel.hasActiveCriteria)
                            .accessibilityIdentifier("clearCriteriaButton")
                    }
                    .padding(.vertical, 4)

                    if isSearchVisible {
                        // $ makes a two-way binding, so typing updates searchText.
                        TextField("Search product, number, or location", text: $viewModel.searchText)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .accessibilityIdentifier("inventorySearchField")
                    }
                }

                // Show a "no results" view when a search matches nothing.
                if viewModel.isSearching, viewModel.locations.all.isEmpty {
                    ContentUnavailableView.search(text: viewModel.searchText)
                        .listRowBackground(Color.clear)
                }

                ForEach(viewModel.locations.shown) { location in
                    // A collapsible section per location, with an expandable row per product.
                    Section(isExpanded: expansionBinding(for: location.id)) {
                        ForEach(location.lines) { line in
                            DisclosureGroup {
                                InventoryLineDetails(line: line)
                            } label: {
                                InventoryLineRow(line: line)
                            }
                        }
                    } header: {
                        LocationHeader(location: location)
                    }
                }

                // Reached the last loaded location: show the next page.
                if viewModel.locations.hasMore {
                    LoadMoreRow { viewModel.locations.loadMore() }
                }
            }
            // Sidebar style gives each section its collapse arrow.
            .listStyle(.sidebar)
            .refreshable {
                await viewModel.loadData(repository: repository, forceRefresh: true)
            }
            .scrollToTopButton(target: ListTop.id)
            // The system large title shrinks into the nav bar on scroll, same as the Dashboard.
            .navigationTitle("Inventory")
            // Load the data when the screen appears.
            .task { await viewModel.loadData(repository: repository) }
        }
    }

    /// Open or closed state for a location. Always open while searching so matches stay visible.
    private func expansionBinding(for locationId: Int64) -> Binding<Bool> {
        // A custom Binding with its own get and set, backed by expandedLocations.
        Binding(
            get: { viewModel.isSearching || expandedLocations.contains(locationId) },
            set: { isExpanded in
                if isExpanded {
                    expandedLocations.insert(locationId)
                } else {
                    expandedLocations.remove(locationId)
                }
            }
        )
    }
}

/// One product at one location
struct InventoryLine: Identifiable, Hashable {
    /// "productId-locationId". Matches Inventory.id.
    let id: String
    let productId: Int64
    let locationId: Int64
    let name: String
    /// Raw product number, used for search. Nil when the API sent none.
    let productNumber: String?
    let productNumberText: String
    let location: String
    let shelfBin: String
    let quantity: Int64
    let reorderPoint: Int64
    let safetyStockLevel: Int64
    let accessibilitySummary: String

    // Copy the values out of Core Data so a cache refresh can't empty the row.
    init(_ item: Inventory) {
        id = item.id
        productId = item.productId
        locationId = item.locationId
        name = item.displayName
        productNumber = item.productNumber
        productNumberText = item.displayProductNumber
        location = item.displayLocation
        shelfBin = item.displayShelfBin
        quantity = item.quantity
        reorderPoint = item.reorderPoint
        safetyStockLevel = item.safetyStockLevel
        accessibilitySummary = item.accessibilitySummary
    }

    var stockLevel: StockLevel {
        StockLevel(quantity: quantity,
                   reorderPoint: reorderPoint,
                   safetyStockLevel: safetyStockLevel)
    }

    /// Out of stock, critical, or at or below the reorder point.
    var needsAttention: Bool { stockLevel.status.isUrgent }

    /// "24% of safety stock", or a note when safety stock is not set.
    var percentOfSafetyText: String {
        guard let fraction = stockLevel.fractionOfSafetyStock else { return "No safety stock set" }
        return "\(fraction.formatted(.percent.precision(.fractionLength(0)))) of safety stock"
    }

    /// Worst stock first. Ties go to name, then ID, so the order never jumps.
    static func worstFirst(_ left: InventoryLine, _ right: InventoryLine) -> Bool {
        // Check both directions to tell "worse" apart from "tied".
        if StockLevel.worstFirst(left.stockLevel, right.stockLevel) { return true }
        if StockLevel.worstFirst(right.stockLevel, left.stockLevel) { return false }
        let comparison = left.name.localizedStandardCompare(right.name)
        return comparison == .orderedSame ? left.id < right.id : comparison == .orderedAscending
    }
}

/// One location made up of its inventory lines
struct LocationGroup: Identifiable, Hashable {
    let locationId: Int64
    let name: String
    let lines: [InventoryLine]

    var id: Int64 { locationId }

    init(locationId: Int64, lines: [InventoryLine]) {
        let sorted = lines.sorted(by: InventoryLine.worstFirst)
        self.locationId = locationId
        self.lines = sorted
        // Every line has the same location name, so read the first one.
        self.name = sorted.first?.location ?? "Location \(locationId)"
    }

    /// How many lines are out of stock, critical, or at the reorder point.
    var needsReorderCount: Int { lines.filter(\.needsAttention).count }

    /// The location whose worst item is in the worst shape goes first.
    static func worstFirst(_ left: LocationGroup, _ right: LocationGroup) -> Bool {
        // Compare each location's worst line. A location with no lines goes last.
        switch (left.lines.first, right.lines.first) {
        case let (leftLine?, rightLine?):
            if InventoryLine.worstFirst(leftLine, rightLine) { return true }
            if InventoryLine.worstFirst(rightLine, leftLine) { return false }
        case (_?, nil): return true
        case (nil, _?): return false
        default: break
        }
        let comparison = left.name.localizedStandardCompare(right.name)
        return comparison == .orderedSame ? left.locationId < right.locationId : comparison == .orderedAscending
    }
}

extension InventoryList {

    // @Observable redraws a view only when a property it reads changes.
    @MainActor
    @Observable
    class ViewModel {
        /// Every location, revealed a page at a time as the user scrolls.
        var locations = PagedItems<LocationGroup>(pageSize: 25)
        var source: CachedDataSource = .notcached
        var errorMessage: String = ""

        private var allLines: [InventoryLine] = []
        // didSet reruns the search whenever the text changes.
        var searchText = "" { didSet { applyCriteria(resetPage: true) } }

        var hasActiveCriteria: Bool { !searchText.isEmpty }

        /// True when the search box has real text, not just spaces.
        var isSearching: Bool { !trimmedSearchText.isEmpty }

        private var trimmedSearchText: String {
            searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        func clearCriteria() {
            searchText = ""
        }

        func setLines(_ values: [InventoryLine]) {
            allLines = values
            applyCriteria(resetPage: false)
        }

        private func applyCriteria(resetPage: Bool) {
            let query = trimmedSearchText
            let matches = allLines.filter { line in
                query.isEmpty || line.name.localizedStandardContains(query)
                    || (line.productNumber ?? "").localizedStandardContains(query)
                    || line.location.localizedStandardContains(query)
            }
            // Group by location once, here, instead of on every redraw.
            let grouped = Dictionary(grouping: matches, by: \.locationId)
                .map { LocationGroup(locationId: $0.key, lines: $0.value) }
                .sorted(by: LocationGroup.worstFirst)
            locations.replace(with: grouped, resetPage: resetPage)
        }

        func loadData(repository: (any TieredCacheRepositoryProtocol<Inventory>)?, forceRefresh: Bool = false) async {
            guard let repository = repository else { return }

            do {
                let (rows, source) = try await repository.getAll(forceRefresh: forceRefresh)
                self.source = source
                // Copy out of Core Data.
                setLines(rows.map(InventoryLine.init))
                print("Loaded \(rows.count) inventory rows in \(locations.all.count) locations from \(source)")
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview { InventoryList() }
