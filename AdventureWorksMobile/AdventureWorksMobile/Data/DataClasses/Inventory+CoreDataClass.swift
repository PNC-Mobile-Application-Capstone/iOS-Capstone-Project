//
//  Inventory+CoreDataClass.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 10/7/26.
//
//

public import Foundation
public import CoreData

public typealias InventoryCoreDataClassSet = NSSet

@objc(Inventory)
public class Inventory: NSManagedObject, Codable {

    enum CodingKeys: String, CodingKey {
        case productId, productName, bin, locationId, locationName, productNumber,
             quantity, reorderPoint, safetyStockLevel, shelf
    }

    public required convenience init(from decoder: any Decoder) throws {

        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext
        else { throw DecoderConfigurationError.missingManagedObjectContext }

        self.init(context: context)

        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required. A row is useless without its key, its count, and the
        // two thresholds we compare the count against.
        self.productId = try container.decode(Int64.self, forKey: .productId)
        self.locationId = try container.decode(Int64.self, forKey: .locationId)
        self.quantity = try container.decode(Int64.self, forKey: .quantity)
        self.reorderPoint = try container.decode(Int64.self, forKey: .reorderPoint)
        self.safetyStockLevel = try container.decode(Int64.self, forKey: .safetyStockLevel)

        // Optional. A null here shows a placeholder instead of breaking
        // the whole list.
        self.productName = try container.decodeIfPresent(String.self, forKey: .productName)
        self.productNumber = try container.decodeIfPresent(String.self, forKey: .productNumber)
        self.locationName = try container.decodeIfPresent(String.self, forKey: .locationName)
        self.shelf = try container.decodeIfPresent(String.self, forKey: .shelf)
        self.bin = try container.decodeIfPresent(Int64.self, forKey: .bin).map { NSNumber(value: $0) }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(productId, forKey: .productId)
        try container.encode(locationId, forKey: .locationId)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(reorderPoint, forKey: .reorderPoint)
        try container.encode(safetyStockLevel, forKey: .safetyStockLevel)
        try container.encodeIfPresent(productName, forKey: .productName)
        try container.encodeIfPresent(productNumber, forKey: .productNumber)
        try container.encodeIfPresent(locationName, forKey: .locationName)
        try container.encodeIfPresent(shelf, forKey: .shelf)
        try container.encodeIfPresent(bin?.int64Value, forKey: .bin)
    }
}
