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

// @objc gives the class the name Core Data looks up in the data model.
@objc(CustomerOrder)
public class CustomerOrder: NSManagedObject, Codable {

    enum CodingKeys: String, CodingKey {
        
        case id, firstName, lastName,
             orderDate, shipDate,
             productName, orderQty,
             customerId, unitPrice,
             lineTotal, orderNumber
    }

    // Decodes one JSON object straight into a new Core Data object.
    public required convenience init(from decoder: any Decoder) throws {

        // Get the Core Data context the repository put in userInfo, or stop.
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext
        else { throw DecoderConfigurationError.missingManagedObjectContext }

        self.init(context: context)

        // Read each JSON field by its CodingKeys name.
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Swagger marks names, shipDate, and productName as nullable, so a null must not fail the list.
        self.id = try container.decode(Int64.self, forKey: .id)
        self.firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        self.lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        self.orderDate = try container.decode(String.self, forKey: .orderDate)
        self.shipDate = try container.decodeIfPresent(String.self, forKey: .shipDate)
        self.productName = try container.decodeIfPresent(String.self, forKey: .productName)
        self.orderQty = try container.decode(Int64.self, forKey: .orderQty)
        self.customerId = try container.decode(Int64.self, forKey: .customerId)
        self.unitPrice = try container.decode(Double.self, forKey: .unitPrice)
        self.lineTotal = try container.decode(Double.self, forKey: .lineTotal)
        self.orderNumber = try container.decode(Int64.self, forKey: .orderNumber)
        
    }

    // Writes the object back out as JSON.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(firstName, forKey: .firstName)
        try container.encodeIfPresent(lastName, forKey: .lastName)
        try container.encode(orderDate, forKey: .orderDate)
        try container.encodeIfPresent(shipDate, forKey: .shipDate)
        try container.encodeIfPresent(productName, forKey: .productName)
        try container.encode(orderQty, forKey: .orderQty)
        try container.encode(customerId, forKey: .customerId)
        try container.encode(unitPrice, forKey: .unitPrice)
        try container.encode(lineTotal, forKey: .lineTotal)
        try container.encode(orderNumber, forKey: .orderNumber)
    }

}
