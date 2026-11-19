//
//  CoreDataDashboardRepository.swift
//  AdventureWorksMobile
//

import Foundation
internal import CoreData

// Everything in the dashboard shows as it was last saved
struct DashboardSnapshot {
    var weeklySales: [WeeklySalesEntry]
    var productPerformance: [ProductPerformanceEntry]
    var lowStock: [LowStockEntry]
    var shifts: [ShiftEntry]
    
    var isEmpty: Bool {
        weeklySales.isEmpty && productPerformance.isEmpty && lowStock.isEmpty && shifts.isEmpty
    }
}

// Thrown when the api cant be reached and only the saved copy comes back
enum DashboardUpdateError: LocalizedError {
    case showingSavedData
    
    var errorDescription: String? { "Showing the last saved dashboard data" }
}


@MainActor
final class CoreDataDashboardRepository: DashboardRepository {
    
    // one repository per endpoint
    private let weeklySales: TieredCacheRepositoryBase<WeeklySales>
    private let productPerformance: TieredCacheRepositoryBase<ProductPerformance>
    private let lowStock: TieredCacheRepositoryBase<LowStockItem>
    private let shifts: TieredCacheRepositoryBase<StaffShift>
    
    // One core data context per list
    private let weeklySalesContext: NSManagedObjectContext
    private let productPerformanceContext: NSManagedObjectContext
    private let lowStockContext: NSManagedObjectContext
    private let shiftsContext: NSManagedObjectContext
    
    init(authStatus: AuthStatus, container: NSPersistentContainer) {
        weeklySalesContext = Self.makeContext(container)
        productPerformanceContext = Self.makeContext(container)
        lowStockContext = Self.makeContext(container)
        shiftsContext = Self.makeContext(container)
        
        // GET /api/Dashboard/weekly-sales
        weeklySales = TieredCacheRepositoryBase(
            authStatus: authStatus,
            urlBase: APIEndpoint.weeklySales.urlString,
            context: weeklySalesContext
        )
        // GET /api/Dashboard/best-worst
        productPerformance = TieredCacheRepositoryBase(
            authStatus: authStatus,
            urlBase: APIEndpoint.bestWorstProducts.urlString,
            context: productPerformanceContext
        )
        // GET /api/Dashboard/low-stock
        lowStock = TieredCacheRepositoryBase(
            authStatus: authStatus,
            urlBase: APIEndpoint.lowStock.urlString,
            context: lowStockContext
        )
        // GET /api/Dashboard/shifts
        shifts = TieredCacheRepositoryBase(
            authStatus: authStatus,
            urlBase: APIEndpoint.shifts.urlString,
            context: shiftsContext
        )
    }
    
    private static func makeContext(_ container: NSPersistentContainer) -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = container.persistentStoreCoordinator
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    // Mark: - Fresh API Data
    
    func getWeeklySales() async throws -> [WeeklySalesEntry] {
        let (records, source) = try await weeklySales.getAll(forceRefresh: true)
        try throwIfSavedOnly(source)
        return Self.weeklySalesEntries(records)
    }
    
    func getProductPerformance() async throws -> [ProductPerformanceEntry] {
        let (records, source) = try await productPerformance.getAll(forceRefresh: true)
        try throwIfSavedOnly(source)
        return Self.performanceEntries(records)
    }
    
    func getLowStock() async throws -> [LowStockEntry] {
        let (records, source) = try await lowStock.getAll(forceRefresh: true)
        try throwIfSavedOnly(source)
        return Self.lowStockEntries(records)
    }
    
    func getShifts() async throws -> [ShiftEntry] {
        let (records, source) = try await shifts.getAll(forceRefresh: true)
        try throwIfSavedOnly(source)
        return Self.shiftEntries(records)
    }
    
    private func throwIfSavedOnly(_ source: CachedDataSource) throws {
        if source == .staleDisk { throw DashboardUpdateError.showingSavedData }
    }
    
    // MARK: - Saved data from Core Data
    
    func loadSaved() -> DashboardSnapshot? {
        let snapshot = DashboardSnapshot(
            weeklySales: Self.weeklySalesEntries(saved(WeeklySales.fetchRequest(), in: weeklySalesContext)),
            productPerformance: Self.performanceEntries(saved(ProductPerformance.fetchRequest(), in: productPerformanceContext)),
            lowStock: Self.lowStockEntries(saved(LowStockItem.fetchRequest(), in: lowStockContext)),
            shifts: Self.shiftEntries(saved(StaffShift.fetchRequest(), in: shiftsContext))
        )
        return snapshot.isEmpty ? nil : snapshot
    }
    
    private func saved<Record: NSFetchRequestResult>(_ request: NSFetchRequest<Record>,
                                                     in context: NSManagedObjectContext) -> [Record] {
        do {
            return try context.fetch(request)
        } catch {
            print("Reading saved \(Record.self) failed: \(error)")
            return []
        }
    }
    
    // MARK: - Copy records into the screen's structs
    // Core Data returns rows in no set order, so each list is sorted here.
    
    private static func weeklySalesEntries(_ records: [WeeklySales]) -> [WeeklySalesEntry] {
        records.map { WeeklySalesEntry($0) }
            .sorted { $0.salesDate < $1.salesDate }
    }
    
    private static func performanceEntries(_ records: [ProductPerformance]) -> [ProductPerformanceEntry] {
        records.map { ProductPerformanceEntry($0) }
            .sorted { $0.unitsSold > $1.unitsSold }
    }
    
    private static func lowStockEntries(_ records: [LowStockItem]) -> [LowStockEntry] {
        // Lowest stock first, then by name so ties never swap places.
        records.map { LowStockEntry($0) }
            .sorted { ($0.stockLevel, $0.productName) < ($1.stockLevel, $1.productName) }
    }
    
    private static func shiftEntries(_ records: [StaffShift]) -> [ShiftEntry] {
        records.map { ShiftEntry($0) }
            .sorted { ($0.lastName, $0.firstName, $0.employeeId) < ($1.lastName, $1.firstName, $1.employeeId) }
    }
}


extension WeeklySalesEntry {
    init(_ record: WeeklySales) {
        self.init(salesDate: record.salesDate ?? .distantPast,
                  totalSales: record.totalSales,
                  totalProfit: record.totalProfit)
    }
}

extension ProductPerformanceEntry {
    init(_ record: ProductPerformance) {
        self.init(productId: Int(record.productId),
                  productName: record.productName ?? "",
                  unitsSold: Int(record.unitsSold),
                  unitsInStock: Int(record.unitsInStock))
    }
}

extension LowStockEntry {
    init(_ record: LowStockItem) {
        self.init(productId: record.productId,
                  productName: record.productName ?? "",
                  stockLevel: record.stockLevel,
                  reorderPoint: record.reorderPoint,
                  safetyStockLevel: record.safetyStockLevel?.int64Value)
    }
}

extension ShiftEntry {
    init(_ record: StaffShift) {
        self.init(employeeId: Int(record.employeeId),
                  firstName: record.firstName ?? "",
                  middleName: record.middleName,
                  lastName: record.lastName ?? "",
                  suffix: record.suffix,
                  shift: record.shift ?? "")
    }
}
