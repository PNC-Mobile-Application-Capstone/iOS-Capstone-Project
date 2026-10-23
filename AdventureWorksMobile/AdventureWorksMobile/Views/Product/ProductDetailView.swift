//
//  ProductDetailView.swift
//  AdventureWorksMobile
//

import SwiftUI

struct ProductDetails: View {
    
    @Environment(\.productRepository) private var repository
    @State private var viewModel = ViewModel()
    @ObservedObject var product: Product
    
    var body: some View {
        // ScrollView keeps the content at the top and lets long pages scroll.
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text(product.name ?? "ERROR")
                    .font(.default)
                    .padding(5)
                
                if viewModel.isLoading && product.detailUpdatedAt == nil {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Loading details…")
                            .foregroundStyle(.secondary)
                    }
                }
                
                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }
            
            Section("Overview") {
                overviewGrid
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
            }
            
            if let summary = product.summary, !summary.isEmpty {
                Section() {
                    Text(summary)
                }
            }
            
            if !product.specs.isEmpty {
                Section("Specifications") {
                    ForEach(product.specs) { row in
                        LabeledContent(row.label, value: row.value)
                    }
                }
            }
            
            if !product.warrantyAndMaintenance.isEmpty {
                Section("Warranty & Maintenance") {
                    ForEach(product.warrantyAndMaintenance) { row in
                        LabeledContent(row.label, value: row.value)
                    }
                }
            }
            
            if product.hasManufacturingData {
                Section("Manufacturing") {
                    manufacturingGrid
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                }
            }
        }
        .navigationTitle("Product #\(product.id)")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.loadDetail(for: product, repository: repository, forceRefresh: true)
        }
        .task { await viewModel.loadDetail(for: product, repository: repository) }
    }
    
    // MARK: - Build components
    
    private var header: some View {
        VStack(spacing: 8) {
            if let data = product.displayPhotoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 200)
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
                    .foregroundStyle(.secondary)
            }
            
            Text(product.name ?? "Unnamed product")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(product.productNumber ?? "")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var overviewGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatBlock(label: "Price",
                      value: product.listPrice.formatted(.currency(code: "USD")))
            StatBlock(label: "Color", value: product.color ?? "—")
            StatBlock(label: "Product Line", value: product.productLineName ?? "—")
            StatBlock(label: "Model", value: product.productModelName ?? "—")
        }
    }
    
    private var manufacturingGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatBlock(label: "Steps", value: "\(product.numberOfSteps)")
            StatBlock(label: "Lot Size", value: "\(product.lotSize)")
            StatBlock(label: "Setup Hours", value: product.setupHours.hoursFormat)
            StatBlock(label: "Machine Hours", value: product.machineHours.hoursFormat)
            StatBlock(label: "Labor Hours", value: product.laborHours.hoursFormat)
        }
    }
}

// MARK: - ViewModel

extension ProductDetails {
    
    @MainActor
    @Observable
    class ViewModel {
        
        var isLoading = false
        var errorMessage = ""
        
        func loadDetail(for product: Product,
                        repository: (any TieredCacheRepositoryProtocol<Product>)?,
                        forceRefresh: Bool = false
        ) async {
            guard let repo = repository as? TieredCacheRepositoryBase<Product> else { return }
            
            isLoading = true
            defer { isLoading = false }
            
            do {
                try await repo.loadDetail(for: product, forceRefresh: forceRefresh)
                errorMessage = ""
            } catch is CancellationError {
                
            } catch let e as URLError where e.code == .cancelled {
                
            } catch {
                errorMessage = error.localizedDescription
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }
}

// MARK: - Display helpers

extension Product {
    
    var displayPhotoData: Data? {
        guard let photo else { return nil }
        if let fileName = photoFileName?.lowercased(), fileName.hasPrefix("no_image_available") {
            return nil
        }
        return photo
    }
    
    var productLineName: String? {
        guard let code = productLine?.trimmingCharacters(in: .whitespaces), !code.isEmpty else { return nil }
        switch code {
        case "R": return "Road"
        case "M": return "Mountain"
        case "T": return "Touring"
        default: return code
        }
    }
    
    var specs: [ProductDetailRow] {
        nonEmptyRows([
            ("Manufacturer", manufacturer),
            ("Frame", bikeFrame),
            ("Material", material),
            ("Style", style),
            ("Crankset", crankset),
            ("Wheels", wheelDescription),
            ("Saddle", saddleDescription),
            ("Pedals", pedalDescription),
            ("Rider Experience", riderExperience),
        ])
    }
    
    var warrantyAndMaintenance: [ProductDetailRow] {
        nonEmptyRows([
            ("Warranty", warrantyDescription),
            ("Warranty Period", warrantyPeriod),
            ("Maintenance", maintenanceDescription)
        ])
    }
    
    
    var hasManufacturingData: Bool {
        numberOfSteps > 0 || lotSize > 0 || setupHours > 0 || machineHours > 0 || laborHours > 0
    }
    
    private func nonEmptyRows(_ rows: [(String, String?)]) -> [ProductDetailRow] {
        rows.compactMap { label, value in
            guard let text = value?
                .split(whereSeparator: \.isWhitespace)
                .joined(separator: " "),
                  !text.isEmpty else { return nil }
            return ProductDetailRow(label: label, value: text)
        }
    }
}

struct ProductDetailRow: Identifiable {
    let label: String
    let value: String
    var id: String { label }
}

private extension Double {
    var hoursFormat: String {
        "\(formatted(.number.precision(.fractionLength(0...1)))) h"
    }
}

#Preview {
    ProductList()
}
