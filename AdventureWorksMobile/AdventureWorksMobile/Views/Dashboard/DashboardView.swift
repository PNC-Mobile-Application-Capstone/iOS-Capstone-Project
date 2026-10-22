//
//  DashboardView.swift
//  AdventureWorksMobile
//
//  Created by user302023 on 10/1/26.
//

import SwiftUI

struct DashboardView: View {
    
    @State private var viewModel: ViewModel
    
    // The repository is passed in so previews can use mock data.
    init(repository: any DashboardRepository) {
        viewModel = ViewModel(repository: repository)
    }
    
    var body: some View {
        PageTemplate("Dashboard") {
            Section("Overview") {
                statGrid
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
            }
            
            Section("Weekly Sales") {
                ForEach(viewModel.lastWeekSales) { entry in
                    HStack {
                        Text(entry.salesDate, format: .dateTime.weekday(.abbreviated))
                        Spacer()
                        // Dollars with no cents.
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
        .task {
            await viewModel.loadData()
        }
    }
    
    
    private var statGrid: some View {
        // Two equal columns of stat blocks.
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatBlock(label: "Weekly Sales", value: viewModel.totalSales.formatted(.currency(code: "USD")))
            StatBlock(label: "Weekly Profit", value: viewModel.totalProfit.formatted(.currency(code: "USD")))
            StatBlock(label: "Low Stock Items", value: "\(viewModel.lowStock.count)")
            StatBlock(label: "Staff On Shift", value: "\(viewModel.shifts.count)")
        }
    }
    
}

extension DashboardView {
    
    // @Observable redraws a view only when a property it reads changes.
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
        
        // The 7 days ending on the newest sales date, oldest first.
        var lastWeekSales: [WeeklySalesEntry] {
            guard let newest = weeklySales.map(\.salesDate).max(),
                  let cutoff = Calendar.current.date(byAdding: .day, value: -6, to: newest)
            else { return [] }

            return weeklySales
                .filter { $0.salesDate >= cutoff }
                .sorted { $0.salesDate < $1.salesDate }
        }
        
        var totalSales: Double {
            lastWeekSales.reduce(0) { $0 + $1.totalSales }
        }
        
        var totalProfit: Double {
            lastWeekSales.reduce(0) { $0 + $1.totalProfit }
        }
        
        // Best seller. prefix(1) keeps only the first item.
        var topSellers: [ProductPerformanceEntry] {
            Array(productPerformance.sorted { $0.unitsSold > $1.unitsSold }.prefix(1))
        }
        
        // Worst seller.
        var underperformers: [ProductPerformanceEntry] {
            Array(productPerformance.sorted { $0.unitsSold < $1.unitsSold }.prefix(1))
        }
        
        func loadData() async {
            // async let starts all four calls at once. Each await then waits for its result.
            async let sales = repository.getWeeklySales()
            async let performance = repository.getProductPerformance()
            async let stock = repository.getLowStock()
            async let staffShifts = repository.getShifts()

            // A failed call only leaves its own section empty.
            do { weeklySales = try await sales }
            catch { print("weekly-sales failed: \(error)") }

            do { productPerformance = try await performance }
            catch { print("best-worst failed: \(error)") }

            do { lowStock = try await stock }
            catch { print("low-stock failed: \(error)") }

            do { shifts = try await staffShifts }
            catch { print("shifts failed: \(error)") }
        }
        
    }
    
}


#Preview {
    DashboardView(repository: MockDashboardRepository())
}
