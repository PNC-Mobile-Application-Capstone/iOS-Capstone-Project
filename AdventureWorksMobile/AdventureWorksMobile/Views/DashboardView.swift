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
                     onRefresh: {
            await viewModel.loadData()
            await loadLinks()
        }) {
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
                        DailySalesRow(entry: entry)
                    }
                }
            }
            
            Section("Product Performance") {
                productTiles
                    .navigationDestination(item: $openedProduct) { product in
                        ProductDetails(product: product)
                    }
                
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
            }
            
            
            Section("Low Stock Alert") {
                ForEach(viewModel.lowStock) { item in
                    productLink(item.productId) {
                        LowStockRow(item: item)
                    }
                }
            }
            
            Section("Today's Shifts") {
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
    
    private var statGrid: some View {
        // Two equal columns of stat blocks, or one column at accessibility Dynamic Type sizes.
        LazyVGrid(columns: twoColumnOrStacked, spacing: 12) {
            StatBlock(label: "Weekly Sales", value: viewModel.totalSales.formatted(.currency(code: "USD")))
            StatBlock(label: "Weekly Profit", value: viewModel.totalProfit.formatted(.currency(code: "USD")))
            StatBlock(label: "Low Stock Items", value: "\(viewModel.lowStock.count)")
            StatBlock(label: "Staff On Shift", value: "\(viewModel.shifts.count)")
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
