//
//  ShiftEntry.swift
//  AdventureWorksMobile
//

import Foundation

struct ShiftEntry: Identifiable, Codable {
    let employeeId: Int
    let firstName: String
    let middleName: String?
    let lastName: String
    let suffix: String?
    let shift: String

    var id: Int { employeeId }

    // Join the name parts, skipping any that are nil or empty.
    var fullName: String {
        [firstName, middleName, lastName, suffix]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
