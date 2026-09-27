//
//  CacheBox.swift
//  SwiftUIDemo
//
//  Created by Tyler Swindell on 9/17/26.
//

import Foundation

/// Reference-type wrapper around a cached network response.
///
/// NSCache (used in CachedRemoteRepoBase) requires its values to be
/// classes, not structs, so a plain (Data, Date) tuple can't be stored in
/// it directly. CacheBox exists purely to satisfy that requirement: it
/// bundles the raw encoded payload together with the timestamp of when it
/// was cached, so the cache can later decide whether an entry is still
/// fresh (see the `maxAge` check in CachedRemoteRepoBase.fetchAll).
class CacheBox {
    
    let payload: Data
    let timestamp: Date
    
    init(payload: Data, timestamp: Date) {
        self.payload = payload
        self.timestamp = timestamp
    }
}
