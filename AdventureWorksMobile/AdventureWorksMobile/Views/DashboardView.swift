//
//  DashboardView.swift
//  AdventureWorksMobile
//

import SwiftUI
internal import CoreData

struct DashboardView: View {
    // Used for finding the product or employee row to open
    @Environment(\.productRepository) private var productRepository
    @Environment(\.employeeRepository) private var employeeRepository
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    @State private var viewModel: ViewModel
    @State private var showsDailySales = false
    
    // the shift tile whose people are showing
    @State private var selectedShift: ShiftGroup.ID?
    @State private var openedProduct: Product?
    
    // The repository is passed in so previews can use mock data.
    init(repository: any DashboardRepository) {
        viewModel = ViewModel(repository: repository)
    }
    
    var body: some View {
        PageTemplate("Dashboard",
                     errorMessage: viewModel.errorMessage,
                     isLoading: viewModel.isLoading,
                     hasLoaded: viewModel.hasLoaded,
                     onRefresh: {
            await viewModel.loadData(forceRefresh: true)
            await loadLinks()
        }) {
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
                            DailySalesRow(entry: entry)
                        }
                    }
                }
            }
            
            Section("Product Performance") {
                sectionFeedback(.performance, isEmpty: viewModel.productPerformance.isEmpty)
                productTiles
                    .navigationDestination(item: $openedProduct) { product in
                        ProductDetails(product: product)
                    }
                
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
            }
            
            
            Section("Low Stock Alert") {
                sectionFeedback(.stock, isEmpty: viewModel.lowStock.isEmpty)
                ForEach(viewModel.lowStock) { item in
                    productLink(item.productId) {
                        LowStockRow(item: item)
                    }
                }
            }
            
            Section("Today's Shifts") {
                sectionFeedback(.shifts, isEmpty: viewModel.shifts.isEmpty)
                shiftTiles
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                
                if let group = viewModel.shiftGroups.first(where: { $0.id == selectedShift }) {
                    if group.people.isEmpty {
                        Text("No one is on the \(group.name) shift today.")
                            .foregroundStyle(.secondary)
                    }

                    ForEach(group.people) { person in
                        let employee = viewModel.employee(for: person)
                        NavigationLink {
                            EmployeeDetails(employee: employee)
                        } label: {
                            ShiftPersonRow(name: person.fullName, jobTitle: employee.jobTitle)
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.loadData()
        }
        .task {
            await loadLinks()
        }
    }
    
    private var twoColumnOrStacked: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 10), count: count)
    }

    private var threeColumnOrStacked: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : 3
        return Array(repeating: GridItem(.flexible(), spacing: 10), count: count)
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
        // Two equal columns of stat blocks, or one column at accessibility Dynamic Type sizes.
        LazyVGrid(columns: twoColumnOrStacked, spacing: 12) {
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
    
    private var productTiles: some View {
        LazyVGrid(columns: twoColumnOrStacked, spacing: 10) {
            if let top = viewModel.topSellers.first {
                productTile(top, label: "Top Seller", systemImage: "chart.line.uptrend.xyaxis", color: .green)
            }
            if let worst = viewModel.underperformers.first {
                productTile(worst, label: "Worst Seller", systemImage: "chart.line.downtrend.xyaxis", color: .red)
            }
        }
    }
    
    @ViewBuilder
    private func productTile(_ entry: ProductPerformanceEntry, label: String, systemImage: String, color: Color) -> some View {
        let product = viewModel.product(for: Int64(entry.productId))
        let tile = ProductTile(label: label,
                               systemImage: systemImage,
                               color: color,
                               unitsSold: entry.unitsSold,
                               productName: entry.productName,
                               showsChevron: product != nil)
        if let product {
            Button {
                openedProduct = product
            } label: {
                tile
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(label): \(entry.productName), \(entry.unitsSold) sold")
            .accessibilityHint("Opens product details")
        } else {
            tile
        }
    }
    private var shiftTiles: some View {
        let currentShift = ShiftKind.current()
        
        return VStack(spacing: 8) {
            LazyVGrid(columns: threeColumnOrStacked, spacing: 10) {
                ForEach(viewModel.shiftGroups) { group in
                    let isSelected = group.id == selectedShift
                    let isOnNow = group.kind == currentShift

                    Button {
                        withAnimation { selectedShift = isSelected ? nil : group.id }
                    } label: {
                        ShiftTile(group: group, isSelected: isSelected, isOnNow: isOnNow)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(group.accessibilityText(isOnNow: isOnNow))
                    .accessibilityHint(isSelected ? "Hides who is working this shift" : "Shows who is working this shift")
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            
            if selectedShift == nil {
                Label("Tap a shift to see who's working", systemImage: "hand.tap")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
    }
    
    
    @ViewBuilder
    private func productLink<Row: View>(_ productId: Int64, @ViewBuilder row: () -> Row) -> some View {
        if let product = viewModel.product(for: productId) {
            NavigationLink {
                ProductDetails(product: product)
            } label: {
                row()
            }
        } else {
            row()
        }
    }
    
    private func loadLinks() async {
        await viewModel.loadLinks(productRepository: productRepository, employeeRepository: employeeRepository)
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
    
    // MARK: - ViewModel
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
        private var completedSections: Set<Area> = []
        var errorMessage: String {
            errors.isEmpty ? "" : "Some dashboard data couldn't be updated. Use Retry in the affected section."
        }
        private var hasShownSaved = false
        
        // products and enployees by id so dashboard rows can open their details
        private var productsById: [Int64: Product] = [:]
        private var employeesById: [Int64: EmployeeRow] = [:]
        
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
        
        var shiftGroups: [ShiftGroup] {
            ShiftGroup.grouping(shifts)
        }
        
        func product(for id: Int64) -> Product? {
            guard let product = productsById[id], product.managedObjectContext != nil else { return nil }
            return product
        }
        
        func employee(for person: ShiftEntry) -> EmployeeRow {
            employeesById[Int64(person.employeeId)] ?? EmployeeRow(shift: person)
        }
        
        func loadData(forceRefresh: Bool = false) async {
            if isLoading {
                guard !forceRefresh else { return }
                await withCheckedContinuation { loadWaiters.append($0) }
                if !Task.isCancelled { await loadData() }
                return
            }
            let hasPendingSections = Area.allCases.contains {
                !completedSections.contains($0) && errors[$0] == nil
            }
            guard forceRefresh || hasPendingSections else { return }
            if !hasShownSaved {
                hasShownSaved = true
                if let saved = repository.loadSaved() {
                    weeklySales = saved.weeklySales
                    productPerformance = saved.productPerformance
                    lowStock = saved.lowStock
                    shifts = saved.shifts
                    if !weeklySales.isEmpty { loadedSections.insert(.sales) }
                    if !productPerformance.isEmpty { loadedSections.insert(.performance) }
                    if !lowStock.isEmpty { loadedSections.insert(.stock) }
                    if !shifts.isEmpty { loadedSections.insert(.shifts) }
                }
            }
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
                  forceRefresh || (!completedSections.contains(area) && errors[area] == nil) else { return }
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
                completedSections.insert(area)
            } catch {
                if !NetworkError.isCancellation(error) {
                    errors[area] = NetworkError.userMessage(for: error)
                }
            }
        }

        func loadLinks(productRepository: (any TieredCacheRepositoryProtocol<Product>)?,
                       employeeRepository: (any TieredCacheRepositoryProtocol<Employee>)?) async {
            if let productRepository {
                do {
                    let (products, _) = try await productRepository.getAll()
                    productsById = Dictionary(products.map { ($0.id, $0) },
                                              uniquingKeysWith: { first, _ in first })
                } catch {
                    print("Product lookup failed: \(error)")
                }
            }
            
            if let employeeRepository {
                do {
                    let (employees, _) = try await employeeRepository.getAll()
                    employeesById = Dictionary(employees.map { ($0.id, EmployeeRow($0)) },
                                               uniquingKeysWith: { first, _ in first })
                } catch {
                    print("Employee lookup failed: \(error)")
                }
            }
        }
        

    }
}


// MARK: - Product components

private struct ProductTile: View {
    let label: String
    let systemImage: String
    let color: Color
    let unitsSold: Int
    let productName: String
    let showsChevron: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    var body: some View {
        let isLarge = dynamicTypeSize.isAccessibilitySize
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label {
                    Text(label)
                } icon: {
                    Image(systemName: systemImage)
                        .foregroundStyle(color)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(isLarge ? nil : 1)
                .minimumScaleFactor(0.8)
                
                Spacer(minLength: 0)
                
                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Text("\(unitsSold) sold")
                .font(.title2)
                .fontWeight(.bold)
            
            if isLarge {
                Text(productName)
                    .font(.footnote)
            } else {
                Text(productName)
                    .font(.footnote)
                    .lineLimit(2, reservesSpace: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(productName), \(unitsSold) sold")
    }
}

private struct DailySalesRow: View {
    let entry: WeeklySalesEntry
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let isLarge = dynamicTypeSize.isAccessibilitySize
        let layout = isLarge
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline))

        layout {
            Text(entry.salesDate, format: .dateTime.weekday(.abbreviated))
            if !isLarge {
                Spacer()
            }
            // Dollars with no cents.
            Text(entry.totalSales, format: .currency(code: "USD").precision(.fractionLength(0)))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(entry.salesDate.formatted(.dateTime.weekday(.wide))), \(entry.totalSales.formatted(.currency(code: "USD").precision(.fractionLength(0))))")
    }
}

private struct LowStockRow: View {
    let item: LowStockEntry
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let isLarge = dynamicTypeSize.isAccessibilitySize
        let level = StockLevel(
            quantity: item.stockLevel,
            reorderPoint: item.reorderPoint,
            safetyStockLevel: item.safetyStockLevel ?? 1000
        )
        let layout = isLarge
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 8))

        layout {
            HStack(alignment: .top, spacing: 8) {
                StockStatusIcon(level: level)
                Text(item.productName)
            }
            if !isLarge {
                Spacer()
            }
            Text("\(item.stockLevel) left")
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(item.productName), \(item.stockLevel) left, \(level.status.label).")
    }
}


// MARK: - Shift components

private struct ShiftTile: View {
    let group: ShiftGroup
    let isSelected: Bool
    let isOnNow: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    var body: some View {
        let isLarge = dynamicTypeSize.isAccessibilitySize
        VStack(spacing: 4) {
            Label(group.name, systemImage: group.systemImage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(isLarge ? nil : 1)
                .minimumScaleFactor(0.7)
            
            Text("\(group.people.count)")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(group.hours ?? " ")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(isLarge ? nil : 1)
                .minimumScaleFactor(0.7)
            
            if !isLarge || isOnNow {
                Text("On now")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
                    .opacity(isOnNow ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.accentColor, lineWidth: isSelected ? 2 : 0)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(group.accessibilityText(isOnNow: isOnNow))
    }
}

private struct ShiftPersonRow: View {
    let name: String
    let jobTitle: String?
    
    var body: some View {
        let trimmedJob = jobTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        VStack(alignment: .leading, spacing: 2) {
            Text(name)
            if !trimmedJob.isEmpty {
                Text(trimmedJob)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(trimmedJob.isEmpty ? name : "\(name), \(trimmedJob).")
    }
}


#Preview {
    DashboardView(repository: MockDashboardRepository())
}
