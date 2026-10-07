//
//  CustomerOrder+CoreDataProperties.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 10/7/26.
//
//

public import Foundation
public import CoreData


public typealias CustomerOrderCoreDataPropertiesSet = NSSet

extension CustomerOrder {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CustomerOrder> {
        return NSFetchRequest<CustomerOrder>(entityName: "CustomerOrder")
    }

    @NSManaged nonisolated public var id: Int64
    @NSManaged nonisolated public var firstName: String?
    @NSManaged nonisolated public var lastName: String?
    @NSManaged nonisolated public var orderDate: String?
    @NSManaged nonisolated public var shipDate: String?
    @NSManaged nonisolated public var productName: String?
    @NSManaged nonisolated public var orderQty: Int64
    @NSManaged nonisolated public var customerId: Int64
    @NSManaged nonisolated public var unitPrice: Double
    @NSManaged nonisolated public var lineTotal: Double
    @NSManaged nonisolated public var orderNumber: Int64

}

extension CustomerOrder : Identifiable {

}
