//
//  ShiftEntry.swift
//  AdventureWorksMobile
//
//  Created by user302023 on 10/1/26.
//

import Foundation

struct ShiftEntry: Identifiable, Codable {
    let employeeId: Int
    let firstName: String
    let middleName: String
    let lastName: String
    let suffix: String
    let shift: String

    var id: Int { employeeId }

    var fullName: String {
        var parts = [firstName]
        if !middleName.isEmpty { parts.append(middleName) }
        parts.append(lastName)
        if !suffix.isEmpty { parts.append(suffix) }
        return parts.joined(separator: " ")
    }
}
