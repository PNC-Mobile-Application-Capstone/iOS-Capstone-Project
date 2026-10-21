//
//  PersistenceController.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 9/20/26.
//

// internal import uses CoreData in this module without exposing it to other modules.
internal import CoreData

/// Owns the Core Data stack. PersistenceController.shared is the one copy the app uses.
struct PersistenceController {
    static let shared = PersistenceController()

    // Bundles the data model, the store, and a main-thread context into one object.
    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        // "DataModel" must match the .xcdatamodeld file name.
        container = NSPersistentContainer(name: "DataModel")
        // /dev/null keeps the store in memory only, for tests and previews.
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        // Load the SQLite store and keep any error to handle below.
        var loadError: NSError?
        container.loadPersistentStores { (storeDescription, error) in
            loadError = error as NSError?
        }

        // The store is only a cache. If it won't open after a model change, delete it and reload.
        if let error = loadError, !inMemory,
           let storeURL = container.persistentStoreDescriptions.first?.url {
            print("Core Data store failed to load (\(error.code)). Rebuilding the cache.")
            do {
                try container.persistentStoreCoordinator.destroyPersistentStore(at: storeURL, type: .sqlite)
            } catch {
                fatalError("Could not remove old store: \(error)")
            }
            container.loadPersistentStores { (storeDescription, error) in
                if let error = error as NSError? {
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                }
            }
        } else if let error = loadError {
            fatalError("Unresolved error \(error), \(error.userInfo)")
        }
        // On conflicts keep the newest values, and pull in saves from other contexts.
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

}
