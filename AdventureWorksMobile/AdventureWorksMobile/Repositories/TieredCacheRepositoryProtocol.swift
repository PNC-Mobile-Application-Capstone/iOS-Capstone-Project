//
//  TieredCachedRepositoryProtocol.swift
//  SwiftUIDemo
//
//  Created by Tyler Swindell on 9/18/26.
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
