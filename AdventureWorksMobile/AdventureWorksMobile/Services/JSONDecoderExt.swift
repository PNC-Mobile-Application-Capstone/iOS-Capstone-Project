//
//  JSONDecoderExt.swift
//  AdventureWorksMobile
//

import Foundation

extension JSONDecoder {

    // Parses API date strings. Tries ISO 8601 with fractional seconds first, then a plain local date and time.
    func useStringDecoderForDate() {

        self.dateDecodingStrategy = .custom { decoder in

            // The date is a single JSON value, so read it as one string.
            let container = try decoder.singleValueContainer()

            // A null date becomes distantPast instead of failing.
            guard let value = try container.decode(String?.self) else {
                return Date.distantPast
            }

            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            if let date = dateFormatter.date(from: value) {
                return date
            }

            dateFormatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
            dateFormatter.timeZone = .current
            if let date = dateFormatter.date(from: value) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid ISO 8601 date: \(value)")
        }

    }

}
