//
//  DateText.swift
//  AdventureWorksMobile
//
//  Shared view for showing an API date string.
//

import SwiftUI

/// Shows an API date like "2014-06-30T00:00:00" as "Jun 30, 2014", or "--" if missing.
struct DateText: View {
    let date: String?

    var body: some View {
        Text(Self.displayDate(date))
    }

    /// Formats an API date string. Falls back to the raw string if it can't be parsed.
    static func displayDate(_ raw: String?) -> String {
        guard let raw, !raw.isEmpty else { return "--" }
        let parser = DateFormatter()
        // en_US_POSIX makes parsing ignore the user's region settings.
        parser.locale = Locale(identifier: "en_US_POSIX")
        // Try each format until one works.
        for format in ["yyyy-MM-dd'T'HH:mm:ss.SSS", "yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd"] {
            parser.dateFormat = format
            if let date = parser.date(from: raw) {
                return date.formatted(date: .abbreviated, time: .omitted)
            }
        }
        return raw
    }

    // Turns an API date string into a Date for sorting. Nil if it can't be parsed.
    static func parseDate(_ raw: String?) -> Date? {
        guard let raw, !raw.isEmpty else { return nil }
        // Try ISO 8601 with and without fractional seconds, then the plain formats in UTC.
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: raw) { return date }
        iso.formatOptions = [.withInternetDateTime]
        if let date = iso.date(from: raw) { return date }

        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.timeZone = TimeZone(secondsFromGMT: 0)
        parser.isLenient = false
        for format in ["yyyy-MM-dd'T'HH:mm:ss.SSS", "yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd"] {
            parser.dateFormat = format
            if let date = parser.date(from: raw) { return date }
        }
        return nil
    }
}

#Preview {
    VStack {
        DateText(date: "2014-06-30T00:00:00")
        DateText(date: nil)
    }
}
