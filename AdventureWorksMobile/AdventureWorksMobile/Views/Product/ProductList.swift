//
//  ProductList.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 9/20/26.
//

import SwiftUI

struct ProductList: View {

    @State private var viewModel = ViewModel()
    @Environment(\.productRepository) private var repository

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ListHeader(title: "Products",
                           source: viewModel.source,
                           errorMessage: viewModel.errorMessage)

                List {
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
            }
            .background(Color(.systemGroupedBackground))
            // Title is drawn by ListHeader so it stays put while the list
            // scrolls. navigationTitle still labels the back button.
            .navigationTitle("Products")
            .toolbar(.hidden, for: .navigationBar)
            .task { await viewModel.loadData(repository: repository) }
        }
    }
}

extension ProductList {

    @Observable
    class ViewModel {
        /// Every product, revealed a page at a time as the user scrolls.
        var items = PagedItems<Product>(pageSize: 25)
        var source: CachedDataSource = .notcached
        var errorMessage: String = ""

        func loadData(repository: (any TieredCacheRepositoryProtocol<Product>)?) async {
            guard let repository = repository else { return }

            do {
                let (products, source) = try await repository.getAll()
                self.source = source
                items.replace(with: products)
                print("Loaded \(products.count) items from \(source)")
            } catch {
                errorMessage = error.localizedDescription
            }
        }

    }
}

#Preview { ProductList() }
