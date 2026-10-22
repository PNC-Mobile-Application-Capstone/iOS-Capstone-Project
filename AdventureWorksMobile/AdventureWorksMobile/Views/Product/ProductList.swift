//
//  ProductList.swift
//  AdventureWorksMobile
//

import SwiftUI

struct ProductList: View {

    @State private var viewModel = ViewModel()
    @State private var isSearchVisible = false
    @Environment(\.productRepository) private var repository

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
        PageTemplate("Products",
                     errorMessage: viewModel.errorMessage,
                     onRefresh: { await viewModel.loadData(repository: repository, forceRefresh: true) }) {
            HStack {
                Button {
                    isSearchVisible.toggle()
                } label: {
                    Label(searchButtonTitle, systemImage: "magnifyingglass")
                }
                .accessibilityIdentifier("productSearchButton")
                Spacer()
                Button("Clear", action: viewModel.clearCriteria)
                    .disabled(!viewModel.hasActiveCriteria)
                    .accessibilityIdentifier("clearCriteriaButton")
            }
            .padding(.vertical, 4)

            if isSearchVisible {
                // $ makes a two-way binding, so typing updates searchText.
                TextField("Search name or product number", text: $viewModel.searchText)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("productSearchField")
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
                .labelsHidden()
                .accessibilityIdentifier("productSortPicker")
            }
        } content: {
            // Show a "no results" view when a search matches nothing.
            if !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               viewModel.items.all.isEmpty {
                ContentUnavailableView.search(text: viewModel.searchText)
                    .listRowBackground(Color.clear)
            }

            ForEach(viewModel.items.shown) { item in
                NavigationLink {
                    ProductDetails(product: item)
                } label: {
                    HStack {
                        Text(item.name ?? "--")
                        Spacer()
                        Text(item.listPrice, format: .currency(code: "USD"))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Reached the last loaded product: show the next page.
            if viewModel.items.hasMore {
                LoadMoreRow { viewModel.items.loadMore() }
            }
        }
        // Load the data when the screen appears.
        .task { await viewModel.loadData(repository: repository) }
    }
}

extension ProductList {

    enum SortOption: String, CaseIterable, Identifiable {
        case name = "Name (A–Z)"
        case priceAscending = "Price: low to high"
        case priceDescending = "Price: high to low"

        var id: String { rawValue }
    }

    // @Observable redraws a view only when a property it reads changes.
    @MainActor
    @Observable
    class ViewModel {
        /// Every product, revealed a page at a time as the user scrolls.
        var items = PagedItems<Product>(pageSize: 25)
        var source: CachedDataSource = .notcached
        var errorMessage: String = ""

        private var allProducts: [Product] = []
        // didSet reruns the search and sort whenever these change.
        var searchText = "" { didSet { applyCriteria(resetPage: true) } }
        var sortOption: SortOption = .name { didSet { applyCriteria(resetPage: true) } }

        var hasActiveCriteria: Bool { !searchText.isEmpty || sortOption != .name }

        func clearCriteria() {
            searchText = ""
            sortOption = .name
        }

        func setProducts(_ values: [Product]) {
            allProducts = values
            applyCriteria(resetPage: false)
        }

        private func applyCriteria(resetPage: Bool) {
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let matches = allProducts.filter { product in
                query.isEmpty || (product.name ?? "").localizedStandardContains(query)
                    || (product.productNumber ?? "").localizedStandardContains(query)
            }
            // Sort by price if chosen, then by name, then by ID so ties never jump.
            let sorted = matches.sorted { left, right in
                if sortOption != .name, left.listPrice != right.listPrice {
                    return sortOption == .priceAscending
                        ? left.listPrice < right.listPrice : left.listPrice > right.listPrice
                }
                let comparison = (left.name ?? "").localizedStandardCompare(right.name ?? "")
                return comparison == .orderedSame ? left.id < right.id : comparison == .orderedAscending
            }
            items.replace(with: sorted, resetPage: resetPage)
        }

        func loadData(repository: (any TieredCacheRepositoryProtocol<Product>)?, forceRefresh: Bool = false) async {
            guard let repository = repository else { return }

            do {
                let (products, source) = try await repository.getAll(forceRefresh: forceRefresh)
                self.source = source
                setProducts(products)
                print("Loaded \(products.count) items from \(source)")
            } catch {
                errorMessage = error.localizedDescription
            }
        }

    }
}

#Preview { ProductList() }
