//
//  PagedItems.swift
//  AdventureWorksMobile
//
//  Shows a long list a page at a time.
//

import SwiftUI

/// Holds every item but shows a page at a time. The API has no paging, so this keeps lists light.
struct PagedItems<Item: Identifiable> {
    let pageSize: Int
    // private(set) means other code can read these, but only this struct can change them.
    private(set) var all: [Item] = []
    private(set) var shownCount: Int

    init(pageSize: Int = 25) {
        self.pageSize = pageSize
        self.shownCount = pageSize
    }

    /// The items the List should show right now.
    var shown: ArraySlice<Item> { all.prefix(shownCount) }

    /// True while there are items left to reveal.
    var hasMore: Bool { shownCount < all.count }

    /// Swaps in new data. Keeps the scroll depth unless resetPage is true, as on search or sort.
    mutating func replace(with items: [Item], resetPage: Bool = false) {
        all = items
        shownCount = resetPage ? pageSize : max(shownCount, pageSize)
    }

    /// Reveals the next page.
    mutating func loadMore() {
        guard hasMore else { return }
        shownCount = min(shownCount + pageSize, all.count)
    }
}

/// Spinner at the bottom of a List. Loads the next page when it scrolls into view.
struct LoadMoreRow: View {
    let loadMore: () -> Void

    var body: some View {
        ProgressView()
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
            .onAppear(perform: loadMore)
    }
}
