//
//  LowStockItem+CoreDataProperties.swift
//  AdventureWorksMobile
//

public import Foundation
public import CoreData


public typealias LowStockItemCoreDataPropertiesSet = NSSet

extension LowStockItem {

    // Builds a fetch request for this entity.
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LowStockItem> {
        return NSFetchRequest<LowStockItem>(entityName: "LowStockItem")
    }

    // @NSManaged means Core Data supplies the storage. nonisolated lets code off the main actor read it.
    @NSManaged nonisolated public var productId: Int64
    @NSManaged nonisolated public var productName: String?
    @NSManaged nonisolated public var stockLevel: Int64
    @NSManaged nonisolated public var reorderPoint: Int64
    /// Optional. Core Data scalars cannot be nil, so this is an NSNumber.
    @NSManaged nonisolated public var safetyStockLevel: NSNumber?

}

extension LowStockItem : Identifiable {
    nonisolated public var id: Int64 { productId }
}
