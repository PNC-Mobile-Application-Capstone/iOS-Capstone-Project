//
//  StatBlock.swift
//  AdventureWorksMobile
//

import SwiftUI

// One labeled number on the dashboard grid.
struct StatBlock: View {

    let label: String
    let value: String

    private var spokenValue: String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return (trimmed == "--" || trimmed == "—" || trimmed.isEmpty) ? "Not listed" : trimmed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label), \(spokenValue)")
    }
}
