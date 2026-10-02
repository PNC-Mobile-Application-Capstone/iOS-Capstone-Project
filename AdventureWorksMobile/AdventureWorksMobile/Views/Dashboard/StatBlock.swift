//
//  StatBlock.swift
//  AdventureWorksMobile
//
//  Created by user302023 on 10/1/26.
//

import SwiftUI

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
