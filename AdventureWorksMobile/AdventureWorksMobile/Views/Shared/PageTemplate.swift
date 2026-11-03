//
//  PageTemplate.swift
//  AdventureWorksMobile
//
//  Shared layout for every tab screen.
//

import SwiftUI

/// The list looks a page can pick.
enum PageListStyle {
    case standard
    /// Gives each Section a collapse arrow.
    case sidebar
}

/// Every tab uses this so they all get the same collapsing title, header row, and scroll-to-top button.
struct PageTemplate<Controls: View, Content: View>: View {
    let title: String
    let errorMessage: String
    let listStyle: PageListStyle
    let showsScrollToTop: Bool
    let onRefresh: (() async -> Void)?
    let controls: Controls
    let content: Content

    @Environment(\.defaultMinListRowHeight) private var defaultMinRowHeight

    /// - Parameters:
    ///   - controls: Search, sort, or other rows that sit under the title and scroll away.
    ///   - content: The page's rows and sections.
    init(_ title: String,
         errorMessage: String = "",
         listStyle: PageListStyle = .standard,
         showsScrollToTop: Bool = true,
         onRefresh: (() async -> Void)? = nil,
         @ViewBuilder controls: () -> Controls,
         @ViewBuilder content: () -> Content) {
        self.title = title
        self.errorMessage = errorMessage
        self.listStyle = listStyle
        self.showsScrollToTop = showsScrollToTop
        self.onRefresh = onRefresh
        self.controls = controls()
        self.content = content()
    }

    private var hasHeader: Bool {
        !errorMessage.isEmpty || Controls.self != EmptyView.self
    }

    var body: some View {
        NavigationStack {
            styledList
                .scrollToTopButton(target: ListTop.id, isEnabled: showsScrollToTop)
                // The system large title shrinks into the nav bar on scroll.
                .navigationTitle(title)
                .toolbarTitleDisplayMode(.inlineLarge)
        }
    }

    private var list: some View {
        List {
            ListHeader(errorMessage: errorMessage) { controls }
            content
        }
        // With no header, ListHeader is a 0 point marker row. This lets it be that small.
        .environment(\.defaultMinListRowHeight, hasHeader ? defaultMinRowHeight : 0)
        .contentMargins(.top, 0, for: .scrollContent)
    }

    @ViewBuilder
    private var refreshableList: some View {
        if let onRefresh {
            list.refreshable { await onRefresh() }
        } else {
            list
        }
    }

    @ViewBuilder
    private var styledList: some View {
        switch listStyle {
        case .standard: refreshableList
        case .sidebar: refreshableList.listStyle(.sidebar)
        }
    }
}

extension PageTemplate where Controls == EmptyView {
    /// For pages with no search or sort.
    init(_ title: String,
         errorMessage: String = "",
         listStyle: PageListStyle = .standard,
         showsScrollToTop: Bool = true,
         onRefresh: (() async -> Void)? = nil,
         @ViewBuilder content: () -> Content) {
        self.init(title,
                  errorMessage: errorMessage,
                  listStyle: listStyle,
                  showsScrollToTop: showsScrollToTop,
                  onRefresh: onRefresh,
                  controls: { EmptyView() },
                  content: content)
    }
}

#Preview("With controls") {
    PageTemplate("Preview") {
        Button("Search") {}
    } content: {
        ForEach(1...60, id: \.self) { Text("Row \($0)") }
    }
}

#Preview("No controls") {
    PageTemplate("Preview") {
        Section("Numbers") {
            ForEach(1...60, id: \.self) { Text("Row \($0)") }
        }
    }
}
