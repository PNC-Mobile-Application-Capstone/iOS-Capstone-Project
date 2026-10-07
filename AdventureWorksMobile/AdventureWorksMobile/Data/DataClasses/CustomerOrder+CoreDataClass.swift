//
//  CustomerOrder+CoreDataClass.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 10/7/26.
//
//

public import Foundation
public import CoreData

public typealias CustomerOrderCoreDataClassSet = NSSet

@objc(CustomerOrder)
public class CustomerOrder: NSManagedObject, Codable {

    enum CodingKeys: String, CodingKey {
        
        case id, firstName, lastName, orderDate, shipDate, productName,
             orderQty, customerId, unitPrice, lineTotal, orderNumber
    }

    public required convenience init(from decoder: any Decoder) throws {

        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext
        else { throw DecoderConfigurationError.missingManagedObjectContext }

        self.init(context: context)

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int64.self, forKey: .id)
        self.firstName = try container.decode(String.self, forKey: .firstName)
        self.lastName = try container.decode(String.self, forKey: .lastName)
        self.orderDate = try container.decode(String.self, forKey: .orderDate)
        self.shipDate = try container.decode(String.self, forKey: .shipDate)
        self.productName = try container.decode(String.self, forKey: .productName)
        self.orderQty = try container.decode(Int64.self, forKey: .orderQty)
        self.customerId = try container.decode(Int64.self, forKey: .customerId)
        self.unitPrice = try container.decode(Double.self, forKey: .unitPrice)
        self.lineTotal = try container.decode(Double.self, forKey: .lineTotal)
        self.orderNumber = try container.decode(Int64.self, forKey: .orderNumber)
        
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encode(orderDate, forKey: .orderDate)
        try container.encode(shipDate, forKey: .shipDate)
        try container.encode(productName, forKey: .productName)
        try container.encode(orderQty, forKey: .orderQty)
        try container.encode(customerId, forKey: .customerId)
        try container.encode(unitPrice, forKey: .unitPrice)
        try container.encode(lineTotal, forKey: .lineTotal)
        try container.encode(orderNumber, forKey: .orderNumber)
    }

}
