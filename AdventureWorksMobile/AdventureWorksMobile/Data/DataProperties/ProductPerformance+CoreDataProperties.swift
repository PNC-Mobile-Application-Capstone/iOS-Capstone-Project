//
//  ProductPerformance+CoreDataProperties.swift
//  AdventureWorksMobile
//

public import Foundation
public import CoreData


public typealias ProductPerformanceCoreDataPropertiesSet = NSSet

extension ProductPerformance {

    // Builds a fetch request for this entity.
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProductPerformance> {
        return NSFetchRequest<ProductPerformance>(entityName: "ProductPerformance")
    }

    // @NSManaged means Core Data supplies the storage. nonisolated lets code off the main actor read it.
    @NSManaged nonisolated public var productId: Int64
    @NSManaged nonisolated public var productName: String?
    @NSManaged nonisolated public var unitsSold: Int64
    @NSManaged nonisolated public var unitsInStock: Int64

}

extension ProductPerformance : Identifiable {
    nonisolated public var id: Int64 { productId }
}
