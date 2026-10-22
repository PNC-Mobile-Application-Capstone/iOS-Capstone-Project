//
//  ListHeader.swift
//  AdventureWorksMobile
//
//  Shared top row for the list screens. It scrolls with the list.
//

import SwiftUI

/// The id of the top row. The scroll-to-top button jumps here.
enum ListTop {
    static let id = "listTop"
}

/// First row of a List. Holds the error text and any search or sort controls, so they scroll away under the title.
struct ListHeader<Controls: View>: View {
    let errorMessage: String
    let controls: Controls

    init(errorMessage: String = "", @ViewBuilder controls: () -> Controls) {
        self.errorMessage = errorMessage
        self.controls = controls()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }
            controls
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // Without borderless, a tap anywhere in the row presses every button in it.
        .buttonStyle(.borderless)
        .id(ListTop.id)
        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 8, trailing: 16))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}

extension ListHeader where Controls == EmptyView {
    /// Error text only, for screens with no search or sort.
    init(errorMessage: String) {
        self.init(errorMessage: errorMessage) { EmptyView() }
    }
}

#Preview {
    List {
        ListHeader(errorMessage: "Could not load orders.") {
            Text("Search and sort controls go here")
        }
        Text("First row")
    }
}
