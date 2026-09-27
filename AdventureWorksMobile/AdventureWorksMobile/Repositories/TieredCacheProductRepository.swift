//
//  TieredCacheProductRepository.swift
//  SwiftUIDemo
//
//  Created by Tyler Swindell on 9/18/26.
//
internal import CoreData

class TieredCacheProductRepository: TieredCacheRepositoryBase<Product> {
    
    override init(authStatus: AuthStatus, urlBase: String, context: NSManagedObjectContext) {
        let url = "\(urlBase)/product"
        super.init(authStatus: authStatus, urlBase: url, context: context)
    }
}
