//
//  DashboardView.swift
//  AdventureWorksMobile
//
//  Created by user302023 on 10/1/26.
//

import SwiftUI

struct DashboardView: View {
    
    @State private var viewModel: ViewModel
    
    init(repository: any DashboardRepository) {
        viewModel = ViewModel(repository: repository)
    }
    
    var body: some View {
        
        NavigationStack {
            List {
                Section("Overview") {
                    statGrid
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                }
                
                Section("Weekly Sales") {
                    ForEach(viewModel.weeklySales) { entry in
                        HStack {
                            Text(entry.salesDate, format: .dateTime.weekday(.abbreviated))
                            Spacer()
                            Text(entry.totalSales, format: .currency(code: "USD").precision(.fractionLength(0)))
                        }
                    }
                }
                
                Section("Top Sellers") {
                    ForEach(viewModel.topSellers) { product in
                        HStack {
                            Text(product.productName)
                            Spacer()
                            Text("\(product.unitsSold) sold")
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Section("Underperforming") {
                    ForEach(viewModel.underperformers) { product in
                        HStack {
                            Text(product.productName)
                            Spacer()
                            Text("\(product.unitsSold) sold")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section("Low Stock Alert") {
                    ForEach(viewModel.lowStock) { item in
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(item.isCritical ? .red : .orange)
                            Text(item.productName)
                            Spacer()
                            Text("\(item.stockLevel) left")
                        }
                    }
                }
                
                Section("Today's Shifts") {
                    ForEach(viewModel.shifts) { shift in
                        HStack {
                            Text(shift.fullName)
                            Spacer()
                            Text(shift.shift)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Dashboard")
        }
        .task {
            await viewModel.loadData()
        }
    }
    
    
    private var statGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatBlock(label: "Weekly Sales", value: viewModel.totalSales.formatted(.currency(code: "USD")))
            StatBlock(label: "Weekly Profit", value: viewModel.totalProfit.formatted(.currency(code: "USD")))
            StatBlock(label: "Low Stock Items", value: "\(viewModel.lowStock.count)")
            StatBlock(label: "Staff On Shift", value: "\(viewModel.shifts.count)")
        }
    }
    
}

extension DashboardView {
    
    @Observable
    class ViewModel {
        
        private var repository: any DashboardRepository
        
        var weeklySales: [WeeklySalesEntry] = []
        var productPerformance: [ProductPerformanceEntry] = []
        var lowStock: [LowStockEntry] = []
        var shifts: [ShiftEntry] = []
        
        init(repository: any DashboardRepository) {
            self.repository = repository
        }
        
        var totalSales: Double {
            weeklySales.reduce(0) { $0 + $1.totalSales }
        }
        
        var totalProfit: Double {
            weeklySales.reduce(0) { $0 + $1.totalProfit }
        }
        
        var topSellers: [ProductPerformanceEntry] {
            Array(productPerformance.sorted { $0.unitsSold > $1.unitsSold }.prefix(2))
        }
        
        var underperformers: [ProductPerformanceEntry] {
            Array(productPerformance.sorted { $0.unitsSold < $1.unitsSold }.prefix(2))
        }
        
        func loadData() async {
            do {
                async let sales = repository.getWeeklySales()
                async let performance = repository.getProductPerformance()
                async let stock = repository.getLowStock()
                async let staffShifts = repository.getShifts()
                
                weeklySales = try await sales
                productPerformance = try await performance
                lowStock = try await stock
                shifts = try await staffShifts
            }
            catch {
                print("Failed to load dashboard data: \(error)")
            }
        }
        
    }
    
}


#Preview {
    DashboardView(repository: MockDashboardRepository())
}
