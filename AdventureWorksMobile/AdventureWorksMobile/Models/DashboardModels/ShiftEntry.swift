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
    let middleName: String?
    let lastName: String
    let suffix: String?
    let shift: String

    var id: Int { employeeId }

    var fullName: String {
        [firstName, middleName, lastName, suffix]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
