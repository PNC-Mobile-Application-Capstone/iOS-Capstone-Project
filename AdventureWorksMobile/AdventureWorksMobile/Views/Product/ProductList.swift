//
//  ProductList.swift
//  AdventureWorksMobile
//

import SwiftUI

struct ProductList: View {

    @State private var viewModel = ViewModel()
    @State private var isSearchVisible = false
    @Environment(\.productRepository) private var repository
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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
        let isLarge = dynamicTypeSize.isAccessibilitySize
        let controlRowLayout = isLarge
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .center))

        PageTemplate("Products",
                     errorMessage: viewModel.errorMessage,
                     isLoading: viewModel.isLoading,
                     hasLoaded: viewModel.hasLoaded,
                     isEmpty: viewModel.isEmpty,
                     onRetry: { await viewModel.loadData(repository: repository, forceRefresh: true) },
                     dataStatus: viewModel.dataStatus,
                     onRefresh: { await viewModel.loadData(repository: repository, forceRefresh: true) }) {
            controlRowLayout {
                Button {
                    isSearchVisible.toggle()
                } label: {
                    Label(searchButtonTitle, systemImage: "magnifyingglass")
                }
                .accessibilityLabel(searchButtonTitle)
                .accessibilityIdentifier("productSearchButton")
                if !isLarge {
                    Spacer()
                }
                Button("Clear", action: viewModel.clearCriteria)
                    .disabled(!viewModel.hasActiveCriteria)
                    .accessibilityLabel("Clear search and sort")
                    .accessibilityIdentifier("clearCriteriaButton")
            }
            .padding(.vertical, 4)

            if isSearchVisible {
                // $ makes a two-way binding, so typing updates searchText.
                TextField("Search name or product number", text: $viewModel.searchText)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityLabel("Search products by name or product number")
                    .accessibilityIdentifier("productSearchField")
            }
            controlRowLayout {
                Text("Sort by")
                    .font(.subheadline)
                    .accessibilityHidden(true)
                if !isLarge {
                    Spacer()
                }
                // Each option's tag is the value the picker writes to sortOption.
                Picker("Sort by", selection: $viewModel.sortOption) {
                    ForEach(SortOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .accessibilityLabel("Sort by")
                .accessibilityValue(viewModel.sortOption.rawValue)
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
                    ProductRow(product: item)
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

private struct ProductRow: View {
    @ObservedObject var product: Product
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let isLarge = dynamicTypeSize.isAccessibilitySize
        let layout = isLarge
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 12))

        layout {
            Text(product.displayName)
            if !isLarge {
                Spacer()
            }
            Text(product.listPrice, format: .currency(code: "USD"))
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(product.accessibilitySummary)
    }
}

extension Product {
    var displayName: String {
        let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Unnamed product" : trimmed
    }

    var accessibilitySummary: String {
        "\(displayName), \(listPrice.formatted(.currency(code: "USD")))."
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
        var dataStatus: DataStatus?
        var errorMessage: String = ""
        private(set) var isLoading = false
        private var loadWaiters: [CheckedContinuation<Void, Never>] = []
        private(set) var hasLoaded = false
        var isEmpty: Bool { allProducts.isEmpty }

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
            if isLoading {
                guard !forceRefresh && !hasLoaded else { return }
                await withCheckedContinuation { loadWaiters.append($0) }
                if !Task.isCancelled && !hasLoaded && errorMessage.isEmpty {
                    await loadData(repository: repository)
                }
                return
            }
            guard forceRefresh || !hasLoaded, let repository else { return }
            isLoading = true
            errorMessage = ""
            defer {
                isLoading = false
                let waiters = loadWaiters
                loadWaiters.removeAll()
                waiters.forEach { $0.resume() }
            }

            do {
                let (products, source) = try await repository.getAll(forceRefresh: forceRefresh)
                try Task.checkCancellation()
                dataStatus = DataStatus(source: source, lastUpdated: repository.lastUpdated)
                hasLoaded = true
                if source == .staleDisk {
                    errorMessage = "Couldn't refresh. Showing saved information."
                }
                setProducts(products)
                print("Loaded \(products.count) items from \(source)")
            } catch {
                if !NetworkError.isCancellation(error) {
                    errorMessage = NetworkError.userMessage(for: error)
                }
            }
        }

    }
}

#Preview { ProductList() }
