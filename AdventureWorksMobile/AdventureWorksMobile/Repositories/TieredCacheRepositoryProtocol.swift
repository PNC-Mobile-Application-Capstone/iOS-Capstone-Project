//
//  TieredCachedRepositoryProtocol.swift
//  AdventureWorksMobile
//

// Where getAll found its data.
enum CachedDataSource: Equatable {
    case memory
    case disk
    case staleDisk
    case notcached
}

// What views need from a cached repository, so they never depend on the concrete class.
@MainActor
protocol TieredCacheRepositoryProtocol<Item> {

    associatedtype Item: Identifiable, Codable

    func getAll(forceRefresh: Bool) async throws -> ([Item], CachedDataSource)
}

// getAll() with no argument uses the cache.
extension TieredCacheRepositoryProtocol {
    
    func getAll() async throws -> ([Item], CachedDataSource) {
        try await getAll(forceRefresh: false)
    }
}
