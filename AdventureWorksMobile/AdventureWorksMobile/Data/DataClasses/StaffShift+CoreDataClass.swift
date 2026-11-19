//
//  StaffShift+CoreDataClass.swift
//  AdventureWorksMobile
//

public import Foundation
public import CoreData

public typealias StaffShiftCoreDataClassSet = NSSet

// @objc gives the class the name Core Data looks up in the data model.
@objc(StaffShift)
public class StaffShift: NSManagedObject, Codable {

    enum CodingKeys: String, CodingKey {
        case employeeId, firstName, middleName, lastName, suffix, shift
    }

    // Decodes one JSON object straight into a new Core Data object.
    public required convenience init(from decoder: any Decoder) throws {

        // Get the Core Data context the repository put in userInfo, or stop.
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext
        else { throw DecoderConfigurationError.missingManagedObjectContext }

        self.init(context: context)

        // Read each JSON field by its CodingKeys name.
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required field
        self.employeeId = try container.decode(Int64.self, forKey: .employeeId)

        // Optional fields
        self.firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        self.middleName = try container.decodeIfPresent(String.self, forKey: .middleName)
        self.lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        self.suffix = try container.decodeIfPresent(String.self, forKey: .suffix)
        self.shift = try container.decodeIfPresent(String.self, forKey: .shift)
    }

    // Writes the object back out as JSON.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(employeeId, forKey: .employeeId)
        try container.encodeIfPresent(firstName, forKey: .firstName)
        try container.encodeIfPresent(middleName, forKey: .middleName)
        try container.encodeIfPresent(lastName, forKey: .lastName)
        try container.encodeIfPresent(suffix, forKey: .suffix)
        try container.encodeIfPresent(shift, forKey: .shift)
    }
}
