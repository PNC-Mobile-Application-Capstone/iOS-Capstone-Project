//
//  ListHeader.swift
//  AdventureWorksMobile
//
//  Shared fixed header for the top-level list screens (Products, Orders).
//

import SwiftUI

/// Fixed header for a list screen.
///
/// It sits above the List, so dragging the list does not move it.
/// Screens that use it hide the system nav bar with
/// `.toolbar(.hidden, for: .navigationBar)` and still set
/// `.navigationTitle` so the back button on the next page has a label.
struct ListHeader: View {
    let title: String
    var source: CachedDataSource
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

            Text(source.label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}

extension CachedDataSource {
    /// Short text shown under the header title.
    var label: String {
        switch self {
        case .memory:       "cached in memory"
        case .disk:         "local disk cache"
        case .notcached:    "fresh api data"
        case .staleDisk:    "stale disk"
        }
    }
}

#Preview {
    ListHeader(title: "Orders", source: .memory)
}
