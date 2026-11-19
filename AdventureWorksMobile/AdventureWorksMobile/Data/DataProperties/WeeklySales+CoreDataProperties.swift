//
//  WeeklySales+CoreDataProperties.swift
//  AdventureWorksMobile
//

public import Foundation
public import CoreData


public typealias WeeklySalesCoreDataPropertiesSet = NSSet

extension WeeklySales {
    
    // Builds a fetch request for this entity.
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WeeklySales> {
        return NSFetchRequest<WeeklySales>(entityName: "WeeklySales")
    }
    
    // @NSManaged means Core Data supplies the storage. nonisolated lets code off the main actor read it.
    @NSManaged nonisolated public var salesDate: Date?
    @NSManaged nonisolated public var totalSales: Double
    @NSManaged nonisolated public var totalProfit: Double
    
}

extension WeeklySales : Identifiable {
    nonisolated public var id: Date { salesDate ?? .distantPast }
}
