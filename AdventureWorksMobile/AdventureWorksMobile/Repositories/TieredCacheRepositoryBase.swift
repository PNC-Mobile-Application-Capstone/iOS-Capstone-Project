//
//  TieredCacheRepositoryBase.swift
//  AdventureWorksMobile
//

internal import CoreData
import Foundation

@MainActor
class TieredCacheRepositoryBase<Item: NSManagedObject & Codable & Identifiable>:
    RemoteRepositoryBase<Item>,
    TieredCacheRepositoryProtocol<Item> {

    private let memoryCache = NSCache<NSString, CacheBox<Item>>()
    private let cacheKeyPrefix = String(describing: Item.self)
    private let maxAge: TimeInterval = 15 * 60

    private let urlBase: String
    private let context: NSManagedObjectContext?
    private let defaults: UserDefaults
    private let now: () -> Date

    private var timestampKey: String {
        "cache.timestamp.\(cacheKeyPrefix).\(urlBase)"
    }

    override init(authStatus: AuthStatus,
                  session: URLSession = .shared,
                  authService: any AuthServicing = AuthService.shared) {
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
         authService: any AuthServicing = AuthService.shared,
         defaults: UserDefaults = .standard,
         now: @escaping () -> Date = Date.init) {
        memoryCache.countLimit = 100
        memoryCache.totalCostLimit = 20 * 1024 * 1024

        self.urlBase = urlBase
        self.context = context
        self.defaults = defaults
        self.now = now

        super.init(authStatus: authStatus, session: session, authService: authService)
        super.implicitContext = context
    }

    func getAll() async throws -> ([Item], CachedDataSource) {
        let currentDate = now()

        if let box = memoryCache.object(forKey: urlBase as NSString),
           currentDate.timeIntervalSince(box.timestamp) <= maxAge {
            return (box.items, .memory)
        }

        guard let context else {
            throw CachingConfigurationError.missingManagedObjectContext
        }

        let diskResults = try await context.perform {
            let request = NSFetchRequest<Item>(entityName: String(describing: Item.self))
            return try context.fetch(request)
        }

        if !diskResults.isEmpty,
           let diskTimestamp = defaults.object(forKey: timestampKey) as? Date,
           currentDate.timeIntervalSince(diskTimestamp) <= maxAge {
            memoryCache.setObject(CacheBox(items: diskResults, timestamp: diskTimestamp),
                                  forKey: urlBase as NSString)
            return (diskResults, .disk)
        }

        do {
            let apiResults = try await fetchAll(urlBase)
            let refreshedResults = try await context.perform {
                diskResults.forEach(context.delete)
                try context.save()

                let request = NSFetchRequest<Item>(entityName: String(describing: Item.self))
                return try context.fetch(request)
            }

            defaults.set(currentDate, forKey: timestampKey)
            let items = refreshedResults.isEmpty ? apiResults : refreshedResults
            memoryCache.setObject(CacheBox(items: items, timestamp: currentDate),
                                  forKey: urlBase as NSString)
            return (items, .notcached)
        } catch {
            await context.perform {
                if context.hasChanges {
                    context.rollback()
                }
            }
            if !diskResults.isEmpty {
                return (diskResults, .staleDisk)
            }
            throw error
        }
    }
}
