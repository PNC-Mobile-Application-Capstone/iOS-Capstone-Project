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
                     isLoading: viewModel.isLoading,
                     hasLoaded: viewModel.hasLoaded,
                     onRefresh: { await viewModel.loadData(forceRefresh: true) }) {
            Section("Overview") {
                statGrid
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
            }
            
            Section("Weekly Sales") {
                sectionFeedback(.sales, isEmpty: viewModel.weeklySales.isEmpty)
                if !viewModel.weeklySales.isEmpty {
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
                                            valueLabel: "$\(entry.totalSales.formatted(.number.notation(.compactName).precision(.fractionLength(1))))"
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
            }

            Section("Top Sellers") {
                sectionFeedback(.performance, isEmpty: viewModel.productPerformance.isEmpty)
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
                sectionFeedback(.performance, isEmpty: viewModel.productPerformance.isEmpty)
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
                sectionFeedback(.stock, isEmpty: viewModel.lowStock.isEmpty)
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
                sectionFeedback(.shifts, isEmpty: viewModel.shifts.isEmpty)
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
    
    
    @ViewBuilder
    private func sectionFeedback(_ area: Area, isEmpty: Bool) -> some View {
        if viewModel.loadingSections.contains(area) {
            ProgressView(viewModel.loadedSections.contains(area) ? "Refreshing…" : "Loading…")
        }
        if let message = viewModel.errors[area] {
            VStack(alignment: .leading, spacing: 8) {
                Text(message)
                    .foregroundStyle(.secondary)
                if viewModel.loadedSections.contains(area) && !isEmpty {
                    Text("Showing previously loaded information.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Button("Retry") {
                    Task { await viewModel.retry(area) }
                }
                .disabled(viewModel.loadingSections.contains(area))
                .accessibilityLabel("Retry \(area.rawValue)")
                .accessibilityIdentifier("retry-\(area.rawValue)")
            }
        } else if viewModel.loadedSections.contains(area) && isEmpty {
            Text("No \(area.rawValue) available.")
                .foregroundStyle(.secondary)
        }
    }

    private var statGrid: some View {
        // Two equal columns of stat blocks.
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatBlock(label: "Weekly Sales", value: viewModel.loadedSections.contains(.sales)
                      ? viewModel.totalSales.formatted(.currency(code: "USD")) : "—")
            StatBlock(label: "Weekly Profit", value: viewModel.loadedSections.contains(.sales)
                      ? viewModel.totalProfit.formatted(.currency(code: "USD")) : "—")
            StatBlock(label: "Low Stock Items", value: viewModel.loadedSections.contains(.stock)
                      ? "\(viewModel.lowStock.count)" : "—")
            StatBlock(label: "Staff On Shift", value: viewModel.loadedSections.contains(.shifts)
                      ? "\(viewModel.shifts.count)" : "—")
        }
    }
    
}

extension DashboardView {

    enum Area: String, CaseIterable {
        case sales = "weekly sales"
        case performance = "product performance"
        case stock = "low-stock products"
        case shifts = "employee shifts"
    }
    
    // @Observable redraws a view only when a property it reads changes.
    @MainActor
    @Observable
    class ViewModel {
        
        private let repository: any DashboardRepository
        private var isLoadingAll = false
        private var loadWaiters: [CheckedContinuation<Void, Never>] = []
        private(set) var loadingSections: Set<Area> = []
        private(set) var loadedSections: Set<Area> = []
        private(set) var errors: [Area: String] = [:]

        var isLoading: Bool { isLoadingAll || !loadingSections.isEmpty }
        var hasLoaded: Bool { !loadedSections.isEmpty }
        
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
        
        func loadData(forceRefresh: Bool = false) async {
            if isLoading {
                guard !forceRefresh else { return }
                await withCheckedContinuation { loadWaiters.append($0) }
                if !Task.isCancelled { await loadData() }
                return
            }
            let hasPendingSections = Area.allCases.contains {
                !loadedSections.contains($0) && errors[$0] == nil
            }
            guard forceRefresh || hasPendingSections else { return }
            isLoadingAll = true
            defer {
                isLoadingAll = false
                resumeWaitingLoads()
            }

            async let sales: Void = loadSection(.sales, forceRefresh: forceRefresh)
            async let performance: Void = loadSection(.performance, forceRefresh: forceRefresh)
            async let stock: Void = loadSection(.stock, forceRefresh: forceRefresh)
            async let shifts: Void = loadSection(.shifts, forceRefresh: forceRefresh)
            _ = await (sales, performance, stock, shifts)
        }

        func retry(_ area: Area) async {
            await loadSection(area, forceRefresh: true)
        }

        private func resumeWaitingLoads() {
            guard !isLoading else { return }
            let waiters = loadWaiters
            loadWaiters.removeAll()
            waiters.forEach { $0.resume() }
        }

        private func loadSection(_ area: Area, forceRefresh: Bool) async {
            guard !loadingSections.contains(area),
                  forceRefresh || (!loadedSections.contains(area) && errors[area] == nil) else { return }
            loadingSections.insert(area)
            errors[area] = nil
            defer {
                loadingSections.remove(area)
                resumeWaitingLoads()
            }

            do {
                switch area {
                case .sales:
                    let values = try await repository.getWeeklySales()
                    try Task.checkCancellation()
                    weeklySales = values
                case .performance:
                    let values = try await repository.getProductPerformance()
                    try Task.checkCancellation()
                    productPerformance = values
                case .stock:
                    let values = try await repository.getLowStock()
                    try Task.checkCancellation()
                    lowStock = values
                case .shifts:
                    let values = try await repository.getShifts()
                    try Task.checkCancellation()
                    shifts = values
                }
                loadedSections.insert(area)
            } catch {
                if !NetworkError.isCancellation(error) {
                    errors[area] = NetworkError.userMessage(for: error)
                }
            }
        }

    }
    
}


#Preview {
    DashboardView(repository: MockDashboardRepository())
}
