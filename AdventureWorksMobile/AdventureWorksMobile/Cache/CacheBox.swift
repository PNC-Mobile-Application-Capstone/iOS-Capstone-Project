//
//  CacheBox.swift
//  AdventureWorksMobile
//

import Foundation

/// Holds managed objects and a timestamp for NSCache, which only stores classes.
final class CacheBox<Item: AnyObject> {
    let items: [Item]
    let timestamp: Date

    init(items: [Item], timestamp: Date) {
        self.items = items
        self.timestamp = timestamp
    }
}
