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
        case name, color, listPrice, productNumber, photo
    }
    
    public required convenience init(from decoder: any Decoder) throws {
        
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext
        else { throw DecoderConfigurationError.missingManagedObjectContext }
        
        self.init(context: context)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int64.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.color = try container.decode(String?.self, forKey: .color)
        self.photo = try container.decodeIfPresent(Data.self, forKey: .photo)
        self.listPrice = try container.decode(Double.self, forKey: .listPrice)
        self.productNumber = try container.decode(String.self, forKey: .productNumber)
        
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(color, forKey: .color)
        try container.encode(listPrice, forKey: .listPrice)
        try container.encode(photo, forKey: .photo)
    }
}
