//
//  Inventory+CoreDataProperties.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 10/7/26.
//
//

public import Foundation
public import CoreData


public typealias InventoryCoreDataPropertiesSet = NSSet

extension Inventory {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Inventory> {
        return NSFetchRequest<Inventory>(entityName: "Inventory")
    }

    @NSManaged nonisolated public var id: Int64
    @NSManaged nonisolated public var productName: String?
    @NSManaged nonisolated public var productNumber: String?
    @NSManaged nonisolated public var safetyStockLevel: Int64
    @NSManaged nonisolated public var reorderPoint: Int64
    @NSManaged nonisolated public var locationId: Int64
    @NSManaged nonisolated public var locationName: String?
    @NSManaged nonisolated public var shelf: String?
    @NSManaged nonisolated public var bin: Int64
    @NSManaged nonisolated public var quantity: Int64

}

extension Inventory : Identifiable {

}
