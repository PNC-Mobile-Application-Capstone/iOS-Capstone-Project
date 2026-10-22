//
//  Product+CoreDataProperties.swift
//  AdventureWorksMobile
//
//

public import Foundation
public import CoreData


public typealias ProductCoreDataPropertiesSet = NSSet

extension Product {
    
    // Builds a fetch request for this entity.
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Product> {
        return NSFetchRequest<Product>(entityName: "Product")
    }

    // @NSManaged means Core Data supplies the storage. nonisolated lets code off the main actor read it.
    @NSManaged nonisolated public var id: Int64
    @NSManaged nonisolated public var color: String?
    @NSManaged nonisolated public var listPrice: Double
    @NSManaged nonisolated public var productNumber: String?
    @NSManaged nonisolated public var name: String?
    @NSManaged nonisolated public var photo: Data?
}

// Identifiable uses the id property so SwiftUI lists can track rows.
extension Product : Identifiable {

}
