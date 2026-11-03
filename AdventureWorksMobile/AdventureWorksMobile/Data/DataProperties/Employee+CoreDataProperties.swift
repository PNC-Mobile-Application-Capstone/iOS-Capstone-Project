//
//  Employee+CoreDataProperties.swift
//  AdventureWorksMobile
//
//

public import Foundation
public import CoreData


public typealias EmployeeCoreDataPropertiesSet = NSSet

extension Employee {

    // Builds a fetch request for this entity.
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Employee> {
        return NSFetchRequest<Employee>(entityName: "Employee")
    }

    // @NSManaged means Core Data supplies the storage. nonisolated lets code off the main actor read it.
    @NSManaged nonisolated public var id: Int64
    @NSManaged nonisolated public var firstName: String?
    @NSManaged nonisolated public var lastName: String?
    @NSManaged nonisolated public var shift: String?
    @NSManaged nonisolated public var department: String?
    @NSManaged nonisolated public var hireDate: String?
    @NSManaged nonisolated public var jobTitle: String?

}

// Identifiable uses the id property so SwiftUI lists can track rows.
extension Employee : Identifiable {

}
