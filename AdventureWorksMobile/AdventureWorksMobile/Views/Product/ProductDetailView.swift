//
//  ProductDetailView.swift
//  AdventureWorksMobile
//

import SwiftUI

struct ProductDetails: View {
    
    @Environment(\.productRepository) private var repository

    var product: Product

    // Photo bytes for this page. The repository handles caching and Core Data.
    @State private var photoData: Data?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(product.name ?? "ERROR")
                    .font(.default)
                    .padding(5)
                
                // Show the photo if it loaded, or a placeholder icon.
                if let data = photoData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 200)
                }
                else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)
                        .foregroundStyle(.secondary)
                }
                
                Text("Product #\(product.id)")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(product.productNumber ?? "ERROR")
                    .padding(5)
                
                
                if product.color != nil  {
                    Text(product.color ?? "ERROR")
                        .padding(5)
                }
                
                
                // Two decimal places. See https://swiftprogramming.com/format-numbers-swiftui/
                Text(product.listPrice, format: .number.precision(.fractionLength(2)))
                    .padding(5)
            }
        }
        .padding()
        .task { await loadPhoto() }
    }

    private func loadPhoto() async {
        // loadPhoto only exists on the concrete product repository, so cast to it.
        guard let repo = repository as? TieredCacheRepositoryBase<Product> else { return }
        do {
            photoData = try await repo.loadPhoto(for: product)
        } catch {
            print("Photo load failed: \(error)")
        }
    }
}

#Preview {
    ProductList()
}
