//
//  TieredCachedRepository.swift
//  SwiftUIDemo
//
//  Created by Tyler Swindell on 9/18/26.
//

internal import CoreData
import Foundation

class TieredCacheRepositoryBase<Item: NSManagedObject & Codable & Identifiable>:
    RemoteRepositoryBase<Item>,
    TieredCacheRepositoryProtocol<Item> {
    
    private let memoryCache = NSCache<NSString, CacheBox>()
    private let cacheKeyPrefix = String(describing: Item.self)
    private let maxAge: TimeInterval = 16 * 60.0                    // 15 mins
    
    private let urlBase: String
    private let context: NSManagedObjectContext?
    
    override init(authStatus: AuthStatus) {
        self.urlBase = ""
        self.context = nil
        super.init(authStatus: authStatus)
    }
    
    init(authStatus: AuthStatus, urlBase: String, context: NSManagedObjectContext) {
        memoryCache.countLimit = 100
        memoryCache.totalCostLimit = 20 * 1024 * 1024
        
        self.urlBase = urlBase
        self.context = context
        
        super.init(authStatus: authStatus)
        super.implicitContext = context
    }
    
    func getAll() async throws -> ([Item], CachedDataSource) {
        
        let now = Date()
        
        // try to resolve the data from memory cache
        if let box = memoryCache.object(forKey: urlBase as NSString) {
            let age = now.timeIntervalSince(box.timestamp)
            if age <= maxAge, let decoded = try? JSONDecoder().decode([Item].self, from: box.payload) {
                // if present return it
                return (decoded, .memory)
            }
        }
        
        // try to resolve data from Core Data
        guard let context = context else {
            throw CachingConfigurationError.missingManagedObjectContext
        }
        let results = try await context.perform {
            let request = NSFetchRequest<Item>(entityName: String(describing: Item.self))
            request.fetchLimit = 10
            return try context.fetch(request)
            
        }
        
        if !results.isEmpty {
            // if present store data in memory cache and return it
            let payload = try JSONEncoder().encode(results)
            let box = CacheBox(payload: payload, timestamp: now)
            memoryCache.setObject(box, forKey: urlBase as NSString)
            
            return(results, .disk)
        }
        
        
        // load the data from the API
        let apiResults = try await fetchAll(urlBase)
        
        // store it in Core Data and return it
        apiResults.forEach { res in
            context.insert(res)
        }
        try context.save()

        return (apiResults, .notcached)
        
    }
    
    
}
