//
//  AdventureWorksMobileApp.swift
//  AdventureWorksMobile
//
//  Created by Nathan Bergman on 9/20/26.
//

import SwiftUI
internal import CoreData

@main
struct AdventureWorksMobileApp: App {
    
    let awAPIURL = "https://api.bootcampcentral.com/api"
    // @StateObject is a property wrapper that creates and owns an
    // ObservableObject for the lifetime of this view/app (as opposed to
    // @ObservedObject, which expects to be handed one that's owned
    // elsewhere). Because AuthStatus is @StateObject here, it's created
    // exactly once, when the app launches, and lives for as long as the
    // app runs.
    @StateObject var authStatus = AuthStatus()
    
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            // Whether the user sees the logged-in app or the login screen
            // is driven entirely by AuthStatus.isLoggedIn, which was
            // itself seeded from whatever tokens were found in the
            // Keychain when AuthStatus was created above.
            if authStatus.isLoggedIn {
                ContentView()
                // configure custom dependency injection
                // Makes Core Data's main-thread context available to
                // any view via @Environment(\.managedObjectContext, ...).
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                // Injects the real, network-backed repositories (as
                // opposed to the mock defaults defined on the
                // EnvironmentKeys in RepoInjectionKeys.swift). Both
                // repositories are handed the same authStatus
                // instance, so they share one source of truth for the
                // current access/refresh tokens.
                    .environment(\.productRepository, TieredCacheProductRepository(authStatus: authStatus,
                                                                                   urlBase: awAPIURL,
                                                                                   context: persistenceController.container.viewContext))
                // Separate from the custom \.artistRepository-style keys
                // above: environmentObject() is how @EnvironmentObject-
                // declared properties (like ContentView's authStatus)
                // receive an ObservableObject by type instead of by key.
                    .environmentObject(authStatus)
            }
            else {
                LoginView()
                    .environmentObject(authStatus)
            }
        }
    }
}
