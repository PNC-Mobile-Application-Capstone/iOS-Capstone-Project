//
//  CacheBox.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 9/20/26.
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
