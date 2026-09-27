//
//  RepoProtocol.swift
//  SwiftUIDemo
//
//  Created by Tyler Swindell on 9/11/26.
//

/// A generic protocol (`<Item>` is a generic parameter, constrained below)
/// describing the basic CRUD operations any repository needs to support,
/// regardless of what model it's fetching.
///
/// SwiftUI views (like ArtistList) depend on `any RepositoryProtocol<Artist>`
/// rather than a concrete class, which is what lets EnvExt.swift/
/// RepoInjectionKeys.swift swap in either a MockArtistRepository (for
/// previews/tests) or a RemoteArtistRepository (for the real app) without
/// the view code changing.
protocol RepositoryProtocol<Item> {
    
    // Item must be Identifiable (so getById/delete can key off item.id)
    // and Codable (so it can be sent/received as JSON).
    associatedtype Item: Identifiable, Codable
    
    func getAll() async throws -> [Item]
    func getById(_ id: Item.ID) async throws -> Item?
    func insert(_ item: Item) async throws -> Item
    func update(_ item: Item) async throws
    func delete(_ item: Item) async throws
    
    
}
