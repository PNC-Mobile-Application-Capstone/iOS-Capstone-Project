//
//  EmployeeDetail.swift
//  AdventureWorksMobile
//

import Foundation

struct EmployeeDetail: Decodable {
    let employeeId: Int64
    let shiftHistory: [EmploymentHistoryEntry]?
    
    var sortedHistory: [EmploymentHistoryEntry] {
        (shiftHistory ?? []).sorted { left, right in
            switch (DateText.parseDate(left.startDate), DateText.parseDate(right.startDate)) {
            case let (leftDate?, rightDate?): return leftDate > rightDate
            case (_?, nil): return true
            case (nil, _?): return false
            default: return left.id < right.id
            }
        }
    }
}

struct EmploymentHistoryEntry: Decodable, Identifiable, Hashable {
    let departmentId: Int64?
    let departmentName: String?
    let departmentGroup: String?
    let shiftId: Int64?
    let shiftName: String?
    let startDate: String?
    let endDate: String?
    
    var id: String {
        "\(departmentId ?? 0)-\(shiftId ?? 0)-\(startDate ?? "")"
    }
}

// MARK: - Display helpers

extension EmploymentHistoryEntry {
    
    var isCurrent: Bool { endDate == nil }
    
    var departmentText: String {
        let name = departmentName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "Department not listed" : name
    }
    
    var groupAndShiftText: String {
        let group = departmentGroup?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let shift = shiftName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let parts = [group, shift.isEmpty ? "" : "\(shift) shift"].filter { !$0.isEmpty }
        return parts.isEmpty ? "--" : parts.joined(separator: " . ")
    }
    
    var dateRangeText: String {
        let end = isCurrent ? "Present" : DateText.displayDate(endDate)
        return "\(DateText.displayDate(startDate)) - \(end)"
    }
    
    var accessibilitySummary: String {
        let start = spokenDate(startDate)
        let end = isCurrent ? "present" : spokenDate(endDate)
        var text = "\(departmentText), \(groupAndShiftText.replacingOccurrences(of: " . ", with: ", "))."
        text += "From \(start) to \(end)."
        if isCurrent { text += " Current position" }
        return text
    }
    
    private func spokenDate(_ raw: String?) -> String {
        DateText.parseDate(raw)?.formatted(date: .long, time: .omitted) ?? "unknown date"
    }
}
