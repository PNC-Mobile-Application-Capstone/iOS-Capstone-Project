//
//  ProductDetailView.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 9/25/26.
//

import SwiftUI

struct CustomerOrderDetails: View {
    
    @Environment(\.customerOrderRepository) private var repository

    var customerOrder: CustomerOrder

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 8) {
                
                Text("\(customerOrder.id)")
                    .padding(5)
                
                Text(customerOrder.productName ?? "ERROR")
                    .font(.default)
                    .padding(5)
                
                Text("Order #\(customerOrder.orderNumber)")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(customerOrder.firstName ?? "ERROR")
                    .padding(5)
                
                Text(customerOrder.lastName ?? "ERROR")
                    .padding(5)
                
                Text("\(customerOrder.orderQty)")
                    .padding(5)
                
                Text("\(customerOrder.customerId)")
                    .padding(5)
                
                Text("\(customerOrder.unitPrice)")
                    .padding(5)
                
                Text("\(customerOrder.lineTotal)")
                    .padding(5)
                
                Text("\(customerOrder.orderNumber)")
                    .padding(5)
                
                Text(customerOrder.orderDate ?? "ERROR")
                    .padding(5)
                
                Text(customerOrder.shipDate ?? "ERROR")
                    .padding(5)
                
                // formatting numbers in text views https://swiftprogramming.com/format-numbers-swiftui/
                Text(customerOrder.unitPrice, format: .number.precision(.fractionLength(2)))
                    .padding(5)
            }
        }
        .padding()
    }
}

#Preview {
    CustomerOrderList()
}
