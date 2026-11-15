//
//  DashboardView.swift
//  AdventureWorksMobile
//

import SwiftUI

struct DashboardView: View {
    
    @State private var viewModel: ViewModel
    @State private var showsDailySales = false
    
    // The repository is passed in so previews can use mock data.
    init(repository: any DashboardRepository) {
        viewModel = ViewModel(repository: repository)
    }
    
    var body: some View {
        PageTemplate("Dashboard",
                     errorMessage: viewModel.errorMessage,
                     onRefresh: { await viewModel.loadData() }) {
            Section("Overview") {
                statGrid
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
            }
            
            Section("Weekly Sales") {
                // Tapping the chart shows or hides the daily list below it.
                Button {
                    withAnimation { showsDailySales = !showsDailySales }
                } label: {
                    VStack {
                        BarChart(
                            entries: viewModel.lastWeekSales.map { entry in
                                    .init(
                                        label: entry.salesDate.formatted(.dateTime.weekday(.abbreviated)),
                                        value: entry.totalSales,
                                        valueLabel: "$\(entry.totalSales.formatted(.number.notation(.compactName).precision(.fractionLength(1))))",
                                        accessibilityText: "\(entry.salesDate.formatted(.dateTime.weekday(.wide))), \(entry.totalSales.formatted(.currency(code: "USD").precision(.fractionLength(0))))"
                                    )
                            })
                        Label(showsDailySales ? "Hide List" : "Show List",
                              systemImage: showsDailySales ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .accessibilityLabel(viewModel.weeklySalesSummary)
                .accessibilityHint(showsDailySales ? "Hides the daily sales list" : "Shows the daily sales list")
                
                if showsDailySales {
                    ForEach(viewModel.lastWeekSales) { entry in
                        HStack {
                            Text(entry.salesDate, format: .dateTime.weekday(.abbreviated))
                            Spacer()
                            // Dollars with no cents.
                            Text(entry.totalSales, format: .currency(code: "USD").precision(.fractionLength(0)))
                        }
                    }
                }
            }
            
            Section("Top Seller") {
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
                        StockStatusIcon(level: StockLevel(
                            quantity: item.stockLevel,
                            reorderPoint: item.reorderPoint,
                            safetyStockLevel: item.safetyStockLevel ?? 1000)
                        )
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
    
    // MARK: - ViewModel
    class ViewModel {
        
        private var repository: any DashboardRepository
        
        var weeklySales: [WeeklySalesEntry] = []
        var productPerformance: [ProductPerformanceEntry] = []
        var lowStock: [LowStockEntry] = []
        var shifts: [ShiftEntry] = []
        var errorMessage = ""
        private var hasShownSaved = false
        
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
        
        var weeklySalesSummary: String {
            guard let best = lastWeekSales.max(by: { $0.totalSales < $1.totalSales }),
                  let worst = lastWeekSales.min(by: { $0.totalSales < $1.totalSales }) else {
                return "Weekly sales chart. No sales data."
            }
            return "Weekly sales chart. Total \(dollars(totalSales)). "
            + "Highest \(weekday(best)), \(dollars(best.totalSales)). "
            + "Lowest \(weekday(worst)), \(dollars(worst.totalSales))."
        }
        
        private func dollars(_ amount: Double) -> String {
            amount.formatted(.currency(code: "USD").precision(.fractionLength(0)))
        }
        
        private func weekday(_ entry: WeeklySalesEntry) -> String {
            entry.salesDate.formatted(.dateTime.weekday(.wide))
        }
        
        
        // Best seller
        var topSellers: [ProductPerformanceEntry] {
            Array(productPerformance.sorted { $0.unitsSold > $1.unitsSold }.prefix(1))
        }
        
        // Worst seller
        var underperformers: [ProductPerformanceEntry] {
            Array(productPerformance.sorted { $0.unitsSold < $1.unitsSold }.prefix(1))
        }
        
        private func isCancelled(_ error: Error) -> Bool {
            error is CancellationError || (error as? URLError)?.code == .cancelled
        }
        
        func loadData() async {
            // 1. Show the last saved dashboard right away, so the screen isn't empty.
            if !hasShownSaved {
                hasShownSaved = true
                if let saved = repository.loadSaved() {
                    weeklySales = saved.weeklySales
                    productPerformance = saved.productPerformance
                    lowStock = saved.lowStock
                    shifts = saved.shifts
                }
            }
            
            // 2. Ask the API for all four at once. Each section updates as soon as its own answer arrives.
            let allUpdated = await withTaskGroup(of: Bool.self) { group -> Bool in
                group.addTask { await self.refreshWeeklySales() }
                group.addTask { await self.refreshProductPerformance() }
                group.addTask { await self.refreshLowStock() }
                group.addTask { await self.refreshShifts() }
                
                var all = true
                for await updated in group where !updated { all = false }
                return all
            }
            
            errorMessage = allUpdated ? "" : "Some dashboard data couldn't be updated. Pull down to try again."
        }
        
        // Each one replaces its section only when the API answers. On failure the saved data stays.
        private func refreshWeeklySales() async -> Bool {
            do { weeklySales = try await repository.getWeeklySales(); return true }
            catch { print("weekly-sales failed: \(error)"); return isCancelled(error) }
        }
        
        private func refreshProductPerformance() async -> Bool {
            do { productPerformance = try await repository.getProductPerformance(); return true }
            catch { print("best-worst failed: \(error)"); return isCancelled(error) }
        }
        
        private func refreshLowStock() async -> Bool {
            do { lowStock = try await repository.getLowStock(); return true }
            catch { print("low-stock failed: \(error)"); return isCancelled(error) }
        }
        
        private func refreshShifts() async -> Bool {
            do { shifts = try await repository.getShifts(); return true }
            catch { print("shifts failed: \(error)"); return isCancelled(error) }
        }
    }
}


#Preview {
    DashboardView(repository: MockDashboardRepository())
}
