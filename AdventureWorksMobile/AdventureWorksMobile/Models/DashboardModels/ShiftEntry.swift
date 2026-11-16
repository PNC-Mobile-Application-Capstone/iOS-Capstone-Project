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

    var fullName: String {
        [firstName, middleName, lastName, suffix]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}


enum ShiftKind: String, CaseIterable {
    case day = "Day"
    case evening = "Evening"
    case night = "Night"

    init?(name: String) {
        let key = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard let match = Self.allCases.first(where: { key.hasPrefix($0.rawValue.lowercased()) })
        else { return nil }
        self = match
    }

    var hours: String {
        switch self {
        case .day:     "7am–3pm"
        case .evening: "3pm–11pm"
        case .night:   "11pm–7am"
        }
    }

    var spokenHours: String {
        switch self {
        case .day:     "7 AM to 3 PM"
        case .evening: "3 PM to 11 PM"
        case .night:   "11 PM to 7 AM"
        }
    }

    var systemImage: String {
        switch self {
        case .day:     "sun.max.fill"
        case .evening: "sunset.fill"
        case .night:   "moon.stars.fill"
        }
    }

    static func current(at date: Date = .now, calendar: Calendar = .current) -> ShiftKind {
        switch calendar.component(.hour, from: date) {
        case 7..<15:  .day
        case 15..<23: .evening
        default:      .night
        }
    }
}

struct ShiftGroup: Identifiable {
    let name: String
    let kind: ShiftKind?
    let people: [ShiftEntry]

    var id: String { name }
    var hours: String? { kind?.hours }
    var systemImage: String { kind?.systemImage ?? "clock" }

    func accessibilityText(isOnNow: Bool) -> String {
        var parts = ["\(name) shift", people.count == 1 ? "1 person" : "\(people.count) people"]
        if let spokenHours = kind?.spokenHours { parts.append(spokenHours) }
        if isOnNow { parts.append("on now") }
        return parts.joined(separator: ", ")
    }

    static func grouping(_ shifts: [ShiftEntry]) -> [ShiftGroup] {
        let byName = [KeyPathComparator(\ShiftEntry.lastName), KeyPathComparator(\ShiftEntry.firstName)]

        var known: [ShiftKind: [ShiftEntry]] = [:]
        var other: [String: [ShiftEntry]] = [:]
        var otherNames: [String] = []

        for entry in shifts {
            if let kind = ShiftKind(name: entry.shift) {
                known[kind, default: []].append(entry)
            } else {
                let trimmed = entry.shift.trimmingCharacters(in: .whitespacesAndNewlines)
                let name = trimmed.isEmpty ? "Unassigned" : trimmed
                if other[name] == nil { otherNames.append(name) }
                other[name, default: []].append(entry)
            }
        }

        let knownGroups = ShiftKind.allCases.map { kind in
            ShiftGroup(name: kind.rawValue, kind: kind, people: (known[kind] ?? []).sorted(using: byName))
        }
        let otherGroups = otherNames.map { name in
            ShiftGroup(name: name, kind: nil, people: (other[name] ?? []).sorted(using: byName))
        }

        if known.isEmpty && !otherGroups.isEmpty { return otherGroups }
        return knownGroups + otherGroups
    }
}
