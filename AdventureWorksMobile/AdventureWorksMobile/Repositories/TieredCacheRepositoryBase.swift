//
//  TieredCacheRepositoryBase.swift
//  AdventureWorksMobile
//

internal import CoreData
import Foundation

// Loads items from memory, then Core Data, then the API. Each cached copy lasts 15 minutes.
@MainActor
class TieredCacheRepositoryBase<Item: NSManagedObject & Codable & Identifiable>:
    RemoteRepositoryBase<Item>,
    TieredCacheRepositoryProtocol<Item> {

    // Memory tier. NSCache keys must be classes, so the URL is used as an NSString.
    private let memoryCache = NSCache<NSString, CacheBox<Item>>()
    private let cacheKeyPrefix = String(describing: Item.self)
    private let maxAge: TimeInterval = 15 * 60

    // Not private, so extensions like the photo loader can build detail URLs.
    let urlBase: String
    private let context: NSManagedObjectContext?
    private let defaults: UserDefaults
    // Tests inject a fake clock. The app uses Date.init.
    private let now: () -> Date

    // UserDefaults key for when the disk cache was last filled.
    private var timestampKey: String { "cache.timestamp.\(cacheKeyPrefix).\(urlBase)" }

    // Init with no cache. Needed because this class overrides the base init.
    override init(authStatus: AuthStatus,
                  session: URLSession = .shared,
                  authService: (any AuthServicing)? = nil) {
        self.urlBase = ""
        self.context = nil
        self.defaults = .standard
        self.now = Date.init
        super.init(authStatus: authStatus, session: session, authService: authService)
    }

    init(authStatus: AuthStatus,
         urlBase: String,
         context: NSManagedObjectContext,
         session: URLSession = .shared,
         authService: (any AuthServicing)? = nil,
         defaults: UserDefaults = .standard,
         now: @escaping () -> Date = Date.init) {
        // Cap the memory cache at 100 entries and 20 MB.
        memoryCache.countLimit = 100
        memoryCache.totalCostLimit = 20 * 1024 * 1024

        self.urlBase = urlBase
        self.context = context
        self.defaults = defaults
        self.now = now

        super.init(authStatus: authStatus, session: session, authService: authService)
        // Tell the base class to decode into Core Data.
        super.implicitContext = context
    }

    func getAll(forceRefresh: Bool) async throws -> ([Item], CachedDataSource) {
        let currentDate = now()
        
        // 1. Memory: use it if it is fresh, unless this is a forced refresh.
        if !forceRefresh {
            if let box = memoryCache.object(forKey: urlBase as NSString),
               currentDate.timeIntervalSince(box.timestamp) <= maxAge { return (box.items, .memory) }
        }

        guard let context else { throw CachingConfigurationError.missingManagedObjectContext }

        // 2. Disk: read the saved rows on the context's queue.
        let diskResults = try await context.perform {
            let request = NSFetchRequest<Item>(entityName: String(describing: Item.self))
            return try context.fetch(request)
        }
        

        // Use the disk rows if they are still fresh, and copy them into memory.
        if !forceRefresh, !diskResults.isEmpty,
           let diskTimestamp = defaults.object(forKey: timestampKey) as? Date,
           currentDate.timeIntervalSince(diskTimestamp) <= maxAge {
            memoryCache.setObject(
                CacheBox(
                    items: diskResults,
                    timestamp: diskTimestamp
                ), forKey: urlBase as NSString)
            
            return (diskResults, .disk)
        }

        // 3. API: replace the saved rows with fresh ones.
        do {
            let apiResults = try await fetchAll(urlBase)
            let refreshedResults = try await context.perform {
                // Delete the old rows, save the new ones, and read them back.
                diskResults.forEach(context.delete)
                try context.save()

                let request = NSFetchRequest<Item>(entityName: String(describing: Item.self))
                return try context.fetch(request)
            }

            defaults.set(currentDate, forKey: timestampKey)
            
            let items = refreshedResults.isEmpty ? apiResults : refreshedResults
            memoryCache.setObject(
                CacheBox(
                    items: items,
                    timestamp: currentDate
                ), forKey: urlBase as NSString)
            
            return (items, .notcached)
            
        } catch {
            // On failure, undo partial changes and fall back to old disk rows if there are any.
            await context.perform {
                if context.hasChanges { context.rollback() }
            }
            if !diskResults.isEmpty { return (diskResults, .staleDisk) }
            throw error
        }
    }
}
