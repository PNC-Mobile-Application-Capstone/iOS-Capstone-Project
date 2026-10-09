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
        case id = "productId"
        case productName, bin, locationId, locationName, productNumber,
             quantity, reorderPoint, safetyStockLevel, shelf
    }

    public required convenience init(from decoder: any Decoder) throws {

        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext
        else { throw DecoderConfigurationError.missingManagedObjectContext }

        self.init(context: context)

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int64.self, forKey: .id)
        self.bin = try container.decode(Int64.self, forKey: .bin)
        self.locationId = try container.decode(Int64.self, forKey: .locationId)
        self.locationName = try container.decode(String.self, forKey: .locationName)
        self.productName = try container.decode(String.self, forKey: .productName)
        self.productNumber = try container.decode(String.self, forKey: .productNumber)
        self.quantity = try container.decode(Int64.self, forKey: .quantity)
        self.reorderPoint = try container.decode(Int64.self, forKey: .reorderPoint)
        self.safetyStockLevel = try container.decode(Int64.self, forKey: .safetyStockLevel)
        self.shelf = try container.decode(String.self, forKey: .shelf)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(bin, forKey: .bin)
        try container.encode(locationId, forKey: .locationId)
        try container.encode(locationName, forKey: .locationName)
        try container.encode(productName, forKey: .productName)
        try container.encode(productNumber, forKey: .productNumber)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(reorderPoint, forKey: .reorderPoint)
        try container.encode(safetyStockLevel, forKey: .safetyStockLevel)
        try container.encode(shelf, forKey: .shelf)
        
    }
}
