//
//  TieredCachedRepositoryProtocol.swift
//  SwiftUIDemo
//
//  Created by Tyler Swindell on 9/18/26.
//

enum CachedDataSource {
    case memory
    case disk
    case notcached
}

protocol TieredCacheRepositoryProtocol<Item> {
    
    associatedtype Item: Identifiable, Codable
    
    func getAll() async throws -> ([Item], CachedDataSource)
}
