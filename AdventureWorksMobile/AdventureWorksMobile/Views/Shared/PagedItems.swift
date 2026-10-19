//
//  PagedItems.swift
//  AdventureWorksMobile
//
//  Shows a long list a page at a time.
//

import SwiftUI

/// Holds every item for a list, but only hands the List one page at a time.
///
/// The API has no paging. Each list endpoint returns everything in one
/// response, and the repository caches it. So the data is already on the
/// phone. This struct keeps the screen light by only building rows for
/// the items shown so far. `LoadMoreRow` asks for the next page when the
/// user scrolls past the last loaded item.
struct PagedItems<Item: Identifiable> {
    let pageSize: Int
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

    /// Swaps in fresh data. Keeps how far the user has scrolled, so coming
    /// back from a details page does not jump them to the top.
    /// Search and sort changes pass resetPage to start with the first page.
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

/// Goes at the bottom of a List. When it scrolls into view, it calls
/// `loadMore`, so the next page appears as the user reaches the end.
struct LoadMoreRow: View {
    let loadMore: () -> Void

    var body: some View {
        ProgressView()
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
            .onAppear(perform: loadMore)
    }
}
