//
//  Inventory+CoreDataClass.swift
//  AdventureWorksMobile
//
//

public import Foundation
public import CoreData

public typealias InventoryCoreDataClassSet = NSSet

// @objc gives the class the name Core Data looks up in the data model.
@objc(Inventory)
public class Inventory: NSManagedObject, Codable {

    enum CodingKeys: String, CodingKey {
        case productId, productName, bin, locationId, locationName, productNumber,
             quantity, reorderPoint, safetyStockLevel, shelf
    }

    // Decodes one JSON object straight into a new Core Data object.
    public required convenience init(from decoder: any Decoder) throws {

        // Get the Core Data context the repository put in userInfo, or stop.
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext
        else { throw DecoderConfigurationError.missingManagedObjectContext }

        self.init(context: context)

        // Read each JSON field by its CodingKeys name.
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required fields. A row is useless without these.
        self.productId = try container.decode(Int64.self, forKey: .productId)
        self.locationId = try container.decode(Int64.self, forKey: .locationId)
        self.quantity = try container.decode(Int64.self, forKey: .quantity)
        self.reorderPoint = try container.decode(Int64.self, forKey: .reorderPoint)
        self.safetyStockLevel = try container.decode(Int64.self, forKey: .safetyStockLevel)

        // Optional fields. A null shows a placeholder instead of breaking the list.
        self.productName = try container.decodeIfPresent(String.self, forKey: .productName)
        self.productNumber = try container.decodeIfPresent(String.self, forKey: .productNumber)
        self.locationName = try container.decodeIfPresent(String.self, forKey: .locationName)
        self.shelf = try container.decodeIfPresent(String.self, forKey: .shelf)
        // Core Data stores an optional number as NSNumber, so wrap the Int64.
        self.bin = try container.decodeIfPresent(Int64.self, forKey: .bin).map { NSNumber(value: $0) }
    }

    // Writes the object back out as JSON.
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
