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
        case productName
    }

    public required convenience init(from decoder: any Decoder) throws {

        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext
        else { throw DecoderConfigurationError.missingManagedObjectContext }

        self.init(context: context)

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int64.self, forKey: .id)
        self.productName = try container.decode(String.self, forKey: .productName)
        
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(productName, forKey: .productName)
    }
}
