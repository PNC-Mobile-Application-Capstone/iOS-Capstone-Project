//
//  ProductPerformance+CoreDataClass.swift
//  AdventureWorksMobile
//

public import Foundation
public import CoreData

public typealias ProductPerformanceCoreDataClassSet = NSSet

// @objc gives the class the name Core Data looks up in the data model.
@objc(ProductPerformance)
public class ProductPerformance: NSManagedObject, Codable {

    enum CodingKeys: String, CodingKey {
        case productId, productName, unitsSold, unitsInStock
    }

    // Decodes one JSON object straight into a new Core Data object.
    public required convenience init(from decoder: any Decoder) throws {

        // Get the Core Data context the repository put in userInfo, or stop.
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext
        else { throw DecoderConfigurationError.missingManagedObjectContext }

        self.init(context: context)

        // Read each JSON field by its CodingKeys name.
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required fields.
        self.productId = try container.decode(Int64.self, forKey: .productId)
        self.unitsSold = try container.decode(Int64.self, forKey: .unitsSold)
        self.unitsInStock = try container.decode(Int64.self, forKey: .unitsInStock)

        // Optional field
        self.productName = try container.decodeIfPresent(String.self, forKey: .productName)
    }

    // Writes the object back out as JSON.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(productId, forKey: .productId)
        try container.encode(unitsSold, forKey: .unitsSold)
        try container.encode(unitsInStock, forKey: .unitsInStock)
        try container.encodeIfPresent(productName, forKey: .productName)
    }
}
