//
//  ScrollToTopButton.swift
//  AdventureWorksMobile
//
//  Floating up-arrow button that jumps a List back to its top row.
//

import SwiftUI

/// Shows the button once the list scrolls past its header. Tapping it scrolls to `target`.
struct ScrollToTopButton: ViewModifier {
    let target: AnyHashable?
    @State private var isScrolledDown = false

    func body(content: Content) -> some View {
        ScrollViewReader { proxy in
            content
                // True once the content has moved 80 points up from its resting spot.
                .onScrollGeometryChange(for: Bool.self) { geometry in
                    geometry.contentOffset.y + geometry.contentInsets.top > 80
                } action: { _, scrolledDown in
                    withAnimation(.snappy) { isScrolledDown = scrolledDown }
                }
                .overlay(alignment: .bottomTrailing) {
                    if isScrolledDown, let target {
                        Button {
                            withAnimation { proxy.scrollTo(target, anchor: .top) }
                        } label: {
                            Image(systemName: "arrow.up")
                                .font(.title3.weight(.semibold))
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(.glass)
                        .buttonBorderShape(.circle)
                        .controlSize(.large)
                        .padding()
                        .transition(.scale.combined(with: .opacity))
                        .accessibilityLabel("Scroll to top")
                        .accessibilityIdentifier("scrollToTopButton")
                    }
                }
        }
    }
}

extension View {
    func scrollToTopButton(target: AnyHashable?) -> some View {
        modifier(ScrollToTopButton(target: target))
    }
}
