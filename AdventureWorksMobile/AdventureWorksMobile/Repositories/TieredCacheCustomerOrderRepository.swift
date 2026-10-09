//
//  TieredCacheCustomerOrderRepository.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 10/9/26.
//

import Foundation
internal import CoreData

/// Loads customer orders from GET /api/Order/customer.
/// The base class handles the memory, disk, and network cache tiers.
class TieredCacheCustomerOrderRepository: TieredCacheRepositoryBase<CustomerOrder> {

    private let customerOrderURL: String

    override init(authStatus: AuthStatus,
                  urlBase: String,
                  context: NSManagedObjectContext,
                  session: URLSession = .shared,
                  authService: (any AuthServicing)? = nil,
                  defaults: UserDefaults = .standard,
                  now: @escaping () -> Date = Date.init) {
        let url = "\(urlBase)/order/customer"
        self.customerOrderURL = url
        super.init(authStatus: authStatus,
                   urlBase: url,
                   context: context,
                   session: session,
                   authService: authService,
                   defaults: defaults,
                   now: now)
    }
}
