//
//  Product+CoreDataProperties.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 9/20/26.
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
    // filled by product list endpoint
    @NSManaged nonisolated public var id: Int64
    @NSManaged nonisolated public var color: String?
    @NSManaged nonisolated public var listPrice: Double
    @NSManaged nonisolated public var productNumber: String?
    @NSManaged nonisolated public var name: String?
    @NSManaged nonisolated public var photo: Data?
    
    // filled by specific product endpoint
    @NSManaged nonisolated public var summary: String?
    @NSManaged nonisolated public var photoFileName: String?
    @NSManaged nonisolated public var productLine: String?
    @NSManaged nonisolated public var productModelId: Int64
    @NSManaged nonisolated public var productModelName: String?
    @NSManaged nonisolated public var wheelDescription: String?
    @NSManaged nonisolated public var saddleDescription: String?
    @NSManaged nonisolated public var pedalDescription: String?
    @NSManaged nonisolated public var riderExperience: String?
    @NSManaged nonisolated public var manufacturer: String?
    @NSManaged nonisolated public var bikeFrame: String?
    @NSManaged nonisolated public var crankset: String?
    @NSManaged nonisolated public var material: String?
    @NSManaged nonisolated public var style: String?
    @NSManaged nonisolated public var warrantyPeriod: String?
    @NSManaged nonisolated public var warrantyDescription: String?
    @NSManaged nonisolated public var maintenanceDescription: String?
    @NSManaged nonisolated public var numberOfSteps: Int64
    @NSManaged nonisolated public var setupHours: Double
    @NSManaged nonisolated public var machineHours: Double
    @NSManaged nonisolated public var laborHours: Double
    @NSManaged nonisolated public var lotSize: Int64
    @NSManaged nonisolated public var detailUpdatedAt: Date?
}

// Identifiable uses the id property so SwiftUI lists can track rows.
extension Product : Identifiable {}
