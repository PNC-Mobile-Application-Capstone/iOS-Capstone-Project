//
//  Inventory+CoreDataProperties.swift
//  AdventureWorksMobile
//
//

public import Foundation
public import CoreData


public typealias InventoryCoreDataPropertiesSet = NSSet

extension Inventory {

    // Builds a fetch request for this entity.
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Inventory> {
        return NSFetchRequest<Inventory>(entityName: "Inventory")
    }

    // @NSManaged means Core Data supplies the storage. nonisolated lets code off the main actor read it.
    @NSManaged nonisolated public var productId: Int64
    @NSManaged nonisolated public var productName: String?
    @NSManaged nonisolated public var productNumber: String?
    @NSManaged nonisolated public var safetyStockLevel: Int64
    @NSManaged nonisolated public var reorderPoint: Int64
    @NSManaged nonisolated public var locationId: Int64
    @NSManaged nonisolated public var locationName: String?
    @NSManaged nonisolated public var shelf: String?
    /// Optional. Core Data scalars cannot be nil, so this is an NSNumber.
    @NSManaged nonisolated public var bin: NSNumber?
    @NSManaged nonisolated public var quantity: Int64

}

extension Inventory : Identifiable {

    /// Product plus location is unique, matching the API route and the Core Data constraint.
    nonisolated public var id: String { "\(productId)-\(locationId)" }
}
