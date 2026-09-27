//
//  Product+CoreDataProperties.swift
//  SwiftUIDemo
//
//  Created by Tyler Swindell on 9/18/26.
//
//

public import Foundation
public import CoreData


public typealias ProductCoreDataPropertiesSet = NSSet

extension Product {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Product> {
        return NSFetchRequest<Product>(entityName: "Product")
    }

    @NSManaged nonisolated public var id: Int64
    @NSManaged nonisolated public var color: String?
    @NSManaged nonisolated public var listPrice: Double
    @NSManaged nonisolated public var productNumber: String?
    @NSManaged nonisolated public var name: String?
    @NSManaged nonisolated public var productId: Int64

}

extension Product : Identifiable {

}
