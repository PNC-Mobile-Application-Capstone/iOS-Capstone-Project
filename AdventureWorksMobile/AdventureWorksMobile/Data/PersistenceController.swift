//
//  PersistenceController.swift
//  SwiftUIDemo
//
//  Created by Tyler Swindell on 9/16/26.
//

// "internal import" is an access-control modifier on the import itself:
// it makes CoreData's types usable inside this module but keeps them from
// being re-exported to anything that imports this module. Functionally it
// behaves like a normal `import CoreData` for this file's own code.
internal import CoreData

/// Owns the app's Core Data stack: the persistent container, its store,
/// and the managed object context views read/write through.
/// `PersistenceController.shared` is the single instance the whole app
/// uses (see SwiftUIDemoApp, which injects
/// `persistenceController.container.viewContext` into the environment as
/// `\.managedObjectContext`).
struct PersistenceController {
    static let shared = PersistenceController()
    
    // NSPersistentContainer bundles together the managed object model
    // (defined in DataModel.xcdatamodeld), the persistent store
    // coordinator, and a main-thread managed object context, so setting
    // up Core Data is a few lines instead of wiring each piece by hand.
    let container: NSPersistentContainer
    
    private init() {
        // "DataModel" must match the .xcdatamodeld file's name exactly;
        // that's how the container finds the entity definitions
        // (ToDoCategory, ToDoItem) at runtime.
        container = NSPersistentContainer(name: "DataModel")
        // Loads (or creates, on first launch) the SQLite store on disk.
        // This is asynchronous in general, but for a local on-device store
        // it typically completes before the closure below fires. A real
        // failure here (corrupt store, disk full, etc.) is treated as
        // unrecoverable, since the rest of the app assumes Core Data is
        // already available by the time it starts making fetches.
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
    
}
