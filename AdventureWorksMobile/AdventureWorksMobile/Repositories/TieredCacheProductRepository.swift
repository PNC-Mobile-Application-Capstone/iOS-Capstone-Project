//
//  TieredCacheProductRepository.swift
//  SwiftUIDemo
//
//  Created by Tyler Swindell on 9/18/26.
//
internal import CoreData

class TieredCacheProductRepository: TieredCacheRepositoryBase<Product> {

    override init(authStatus: AuthStatus,
                  urlBase: String,
                  context: NSManagedObjectContext,
                  session: URLSession = .shared,
                  authService: any AuthServicing = AuthService.shared,
                  defaults: UserDefaults = .standard,
                  now: @escaping () -> Date = Date.init) {
        let url = "\(urlBase)/product"
        super.init(authStatus: authStatus,
                   urlBase: url,
                   context: context,
                   session: session,
                   authService: authService,
                   defaults: defaults,
                   now: now)
    }
}
