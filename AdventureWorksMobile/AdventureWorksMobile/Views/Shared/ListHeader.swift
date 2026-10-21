//
//  ListHeader.swift
//  AdventureWorksMobile
//
//  Shared fixed header for the top-level list screens (Products, Orders).
//

import SwiftUI

/// Fixed title above a List. Screens hide the nav bar but keep navigationTitle for the back button.
struct ListHeader: View {
    let title: String
    var errorMessage: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}

#Preview {
    ListHeader(title: "Orders")
}
