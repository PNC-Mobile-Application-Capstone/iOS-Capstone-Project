//
//  StatBlock.swift
//  AdventureWorksMobile
//

import SwiftUI

// One labeled number on the dashboard grid.
struct StatBlock: View {

    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}
