//
//  TieredCacheInventoryRepository.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 10/9/26.
//

import Foundation
internal import CoreData

/// Loads stock levels from GET /api/Inventory.
/// The base class handles the memory, disk, and network cache tiers.
class TieredCacheInventoryRepository: TieredCacheRepositoryBase<Inventory> {

    private let inventoryURL: String

    override init(authStatus: AuthStatus,
                  urlBase: String,
                  context: NSManagedObjectContext,
                  session: URLSession = .shared,
                  authService: (any AuthServicing)? = nil,
                  defaults: UserDefaults = .standard,
                  now: @escaping () -> Date = Date.init) {
        let url = "\(urlBase)/inventory"
        self.inventoryURL = url
        super.init(authStatus: authStatus,
                   urlBase: url,
                   context: context,
                   session: session,
                   authService: authService,
                   defaults: defaults,
                   now: now)
    }
}
