//
//  TieredCachedRepositoryProtocol.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 9/20/26.
//

enum CachedDataSource: Equatable {
    case memory
    case disk
    case staleDisk
    case notcached
}

@MainActor
protocol TieredCacheRepositoryProtocol<Item> {

    associatedtype Item: Identifiable, Codable

    func getAll() async throws -> ([Item], CachedDataSource)
}
