//
//  StaffShift+CoreDataProperties.swift
//  AdventureWorksMobile
//

public import Foundation
public import CoreData

public typealias StaffShiftCoreDataPropeertiesSet = NSCountedSet

extension StaffShift {
    
    // Builds a fetch request for this entity
    @nonobjc public class  func fetchRequest() -> NSFetchRequest<StaffShift> {
        return NSFetchRequest<StaffShift>(entityName: "StaffShift")
    }
    
    // @NSManaged means Core Data supplies the storage. nonisolated lets code off the main actor read it.
    @NSManaged nonisolated public var employeeId: Int64
    @NSManaged nonisolated public var firstName: String?
    @NSManaged nonisolated public var middleName: String?
    @NSManaged nonisolated public var lastName: String?
    @NSManaged nonisolated public var suffix: String?
    @NSManaged nonisolated public var shift: String?
}

extension StaffShift : Identifiable {
    nonisolated public var id: Int64 { employeeId }
}
