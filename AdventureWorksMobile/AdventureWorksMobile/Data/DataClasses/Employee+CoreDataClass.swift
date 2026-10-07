//
//  Employee+CoreDataClass.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 10/7/26.
//
//

public import Foundation
public import CoreData

public typealias EmployeeCoreDataClassSet = NSSet

@objc(Employee)
public class Employee: NSManagedObject, Codable {
    
    enum CodingKeys: String, CodingKey {
        case id = "employeeId"
        case firstName, lastName, shift, department, hireDate, jobTitle
    }

    public required convenience init(from decoder: any Decoder) throws {

        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext
        else { throw DecoderConfigurationError.missingManagedObjectContext }

        self.init(context: context)

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int64.self, forKey: .id)
        self.firstName = try container.decode(String.self, forKey: .firstName)
        self.lastName = try container.decode(String.self, forKey: .lastName)
        self.shift = try container.decode(String.self, forKey: .shift)
        self.department = try container.decode(String.self, forKey: .department)
        self.hireDate = try container.decode(String.self, forKey: .hireDate)
        self.jobTitle = try container.decode(String.self, forKey: .jobTitle)
        
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encode(shift, forKey: .shift)
        try container.encode(department, forKey: .department)
        try container.encode(hireDate, forKey: .hireDate)
        try container.encode(jobTitle, forKey: .jobTitle)
    }
}
