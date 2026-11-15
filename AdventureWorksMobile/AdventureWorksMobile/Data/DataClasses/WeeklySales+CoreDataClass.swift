//
//  WeeklySales+CoreDataClass.swift
//  AdventureWorksMobile
//

public import Foundation
public import CoreData

public typealias WeeklySalesCoreDataClassSet = NSSet

// @objc gives the class the name Core Data looks up in the data model.
@objc(WeeklySales)
public class WeeklySales: NSManagedObject, Codable {
    
    enum CodingKeys: String, CodingKey {
        case salesDate, totalSales, totalProfit
    }
    
    // Decodes one JSON object straight into a new Core Data object.
    public required convenience init(from decoder: any Decoder) throws {
        
        // Get the Core Data context the repository put in userInfo, or stop.
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext
                else { throw DecoderConfigurationError.missingManagedObjectContext }
        
        self.init(context: context)
        
        // Read each JSON field by its CodingKeys name.
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields
        self.salesDate = try container.decode(Date.self, forKey: .salesDate)
        self.totalSales = try container.decode(Double.self, forKey: .totalSales)
        self.totalProfit = try container.decode(Double.self, forKey: .totalProfit)
    }
    
    // Writes the object back out as JSON.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(salesDate, forKey: .salesDate)
        try container.encode(totalSales, forKey: .totalSales)
        try container.encode(totalProfit, forKey: .totalProfit)
    }
}
