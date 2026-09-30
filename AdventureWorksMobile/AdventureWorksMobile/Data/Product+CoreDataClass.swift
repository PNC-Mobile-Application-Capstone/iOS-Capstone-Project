//
//  Product+CoreDataClass.swift
//  SwiftUIDemo
//
//  Created by Tyler Swindell on 9/18/26.
//
//

public import Foundation
public import CoreData

public typealias ProductCoreDataClassSet = NSSet

@objc(Product)
public class Product: NSManagedObject, Codable {

    enum CodingKeys: String, CodingKey {
        case id = "productId"
        case name, color, listPrice, productNumber
    }

    public required convenience init(from decoder: any Decoder) throws {

        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext
        else { throw DecoderConfigurationError.missingManagedObjectContext }

        self.init(context: context)

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int64.self, forKey: .id)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.color = try container.decodeIfPresent(String.self, forKey: .color)
        self.listPrice = try container.decodeIfPresent(Double.self, forKey: .listPrice) ?? 0
        self.productNumber = try container.decodeIfPresent(String.self, forKey: .productNumber)

    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(color, forKey: .color)
        try container.encode(listPrice, forKey: .listPrice)
        try container.encode(productNumber, forKey: .productNumber)
    }
}
