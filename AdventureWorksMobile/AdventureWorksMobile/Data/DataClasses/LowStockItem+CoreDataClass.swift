//
//  LowStockItem+CoreDataClass.swift
//  AdventureWorksMobile
//

public import Foundation
public import CoreData

public typealias LowStockItemCoreDataClassSet = NSSet

// @objc gives the class the name Core Data looks up in the data model.
@objc(LowStockItem)
public class LowStockItem: NSManagedObject, Codable {

    enum CodingKeys: String, CodingKey {
        case productId, productName, stockLevel, reorderPoint, safetyStockLevel
    }

    // Decodes one JSON object straight into a new Core Data object.
    public required convenience init(from decoder: any Decoder) throws {

        // Get the Core Data context the repository put in userInfo, or stop.
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext
        else { throw DecoderConfigurationError.missingManagedObjectContext }

        self.init(context: context)

        // Read each JSON field by its CodingKeys name.
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.productId = try container.decode(Int64.self, forKey: .productId)
        self.stockLevel = try container.decode(Int64.self, forKey: .stockLevel)
        self.reorderPoint = try container.decode(Int64.self, forKey: .reorderPoint)

        // Optional fields
        self.productName = try container.decodeIfPresent(String.self, forKey: .productName)
        // Core Data stores an optional number as NSNumber, so wrap the Int64.
        self.safetyStockLevel = try container.decodeIfPresent(Int64.self, forKey: .safetyStockLevel)
            .map { NSNumber(value: $0) }
    }

    // Writes the object back out as JSON.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(productId, forKey: .productId)
        try container.encode(stockLevel, forKey: .stockLevel)
        try container.encode(reorderPoint, forKey: .reorderPoint)
        try container.encodeIfPresent(productName, forKey: .productName)
        try container.encodeIfPresent(safetyStockLevel?.int64Value, forKey: .safetyStockLevel)
    }
}
