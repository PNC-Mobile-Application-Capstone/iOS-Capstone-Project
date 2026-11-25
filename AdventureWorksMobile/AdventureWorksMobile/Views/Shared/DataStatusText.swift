//
//  DataStatusText.swift
//  AdventureWorksMobile
//
//  Tells the user how fresh a list is: "Last updated 2:41 PM" or "Offline, showing saved data".
//

import SwiftUI

/// Where a list's data came from and when it was last fetched from the API.
struct DataStatus: Equatable {
    var source: CachedDataSource
    var lastUpdated: Date?

    var isOffline: Bool { source == .staleDisk }

    /// The line to show, or nil when there is nothing useful to say.
    func message(now: Date = .now, calendar: Calendar = .current) -> String? {
        let time = lastUpdated.map { Self.format($0, now: now, calendar: calendar) }
        if isOffline {
            guard let time else { return "Offline, showing saved data" }
            return "Offline, showing saved data from \(time)"
        }
        guard let time else { return nil }
        return "Last updated \(time)"
    }

    /// Just the time for today, otherwise the date too.
    private static func format(_ date: Date, now: Date, calendar: Calendar) -> String {
        if calendar.isDate(date, inSameDayAs: now) {
            return date.formatted(date: .omitted, time: .shortened)
        }
        return date.formatted(date: .abbreviated, time: .shortened)
    }
}

/// Small grey line under the title. Turns orange with a wifi icon when offline.
struct DataStatusText: View {
    let status: DataStatus

    var body: some View {
        if let message = status.message() {
            Label(message, systemImage: status.isOffline ? "wifi.slash" : "clock")
                .font(.caption)
                .foregroundStyle(status.isOffline ? .orange : .secondary)
                .accessibilityIdentifier("dataStatusText")
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        DataStatusText(status: DataStatus(source: .notcached, lastUpdated: .now))
        DataStatusText(status: DataStatus(source: .staleDisk, lastUpdated: .now.addingTimeInterval(-86_400)))
        DataStatusText(status: DataStatus(source: .staleDisk, lastUpdated: nil))
    }
}
