//
//  Employee+CoreDataProperties.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 10/7/26.
//
//

public import Foundation
public import CoreData


public typealias EmployeeCoreDataPropertiesSet = NSSet

extension Employee {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Employee> {
        return NSFetchRequest<Employee>(entityName: "Employee")
    }

    @NSManaged nonisolated public var id: Int64
    @NSManaged nonisolated public var firstName: String?
    @NSManaged nonisolated public var lastName: String?
    @NSManaged nonisolated public var shift: String?
    @NSManaged nonisolated public var department: String?
    @NSManaged nonisolated public var hireDate: String?
    @NSManaged nonisolated public var jobTitle: String?

}

extension Employee : Identifiable {

}
