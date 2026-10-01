//
//  ProductDetailView.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 9/25/26.
//

import SwiftUI

struct ProductDetails: View {
    
    var product: Product

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Product #\(product.id)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text(product.name ?? "ERROR")
                    .font(.default)
                    .padding(5)
                Text(product.productNumber ?? "ERROR")
                    .padding(5)
                Text(product.color ?? "ERROR")
                    .padding(5)
                // formatting numbers in text views https://swiftprogramming.com/format-numbers-swiftui/
                Text(product.listPrice, format: .number.precision(.fractionLength(2)))
                    .padding(5)
            }
        }
        .padding()
    }
}

#Preview {
    ProductList()
}
