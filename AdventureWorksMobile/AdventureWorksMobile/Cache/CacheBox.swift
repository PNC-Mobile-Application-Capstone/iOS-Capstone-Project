//
//  CacheBox.swift
//  SwiftUIDemo
//
//  Created by Tyler Swindell on 9/17/26.
//

import Foundation

/// Reference-type wrapper used by `NSCache`.
///
/// Managed objects are retained directly instead of being encoded and decoded.
/// Decoding a managed object requires a context and would create duplicate
/// objects, which made the previous JSON-backed memory cache unreliable.
final class CacheBox<Item: AnyObject> {
    let items: [Item]
    let timestamp: Date

    init(items: [Item], timestamp: Date) {
        self.items = items
        self.timestamp = timestamp
    }
}
