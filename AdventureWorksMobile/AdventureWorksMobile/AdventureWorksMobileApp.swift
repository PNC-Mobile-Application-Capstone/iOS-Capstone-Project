//
//  AdventureWorksMobileApp.swift
//  AdventureWorksMobile
//
//  Created by Nathan Bergman on 9/20/26.
//

import Foundation
import SwiftUI
internal import CoreData

@main
struct AdventureWorksMobileApp: App {

    private static let awAPIURL = "https://api.bootcampcentral.com/api"
    // @StateObject is a property wrapper that creates and owns an
    // ObservableObject for the lifetime of this view/app (as opposed to
    // @ObservedObject, which expects to be handed one that's owned
    // elsewhere). Because AuthStatus is @StateObject here, it's created
    // exactly once, when the app launches, and lives for as long as the
    // app runs.
    @StateObject private var authStatus: AuthStatus
    private let persistenceController: PersistenceController
    private let productRepository: TieredCacheProductRepository
    private let customerOrderRepository: TieredCacheCustomerOrderRepository
    private let inventoryRepository: TieredCacheInventoryRepository
    private let employeeRepository: TieredCacheEmployeeRepository

    init() {
        let authStatus = AuthStatus()
        if ProcessInfo.processInfo.arguments.contains("--ui-testing-reset-auth") {
            authStatus.logout()
        }
        let persistenceController = PersistenceController.shared
        _authStatus = StateObject(wrappedValue: authStatus)
        self.persistenceController = persistenceController
        self.productRepository = TieredCacheProductRepository(
            authStatus: authStatus,
            urlBase: Self.awAPIURL,
            context: persistenceController.container.viewContext
        )
        self.customerOrderRepository = TieredCacheCustomerOrderRepository(
            authStatus: authStatus,
            urlBase: Self.awAPIURL,
            context: persistenceController.container.viewContext
        )
        self.inventoryRepository = TieredCacheInventoryRepository(
            authStatus: authStatus,
            urlBase: Self.awAPIURL,
            context: persistenceController.container.viewContext
        )
        self.employeeRepository = TieredCacheEmployeeRepository(
            authStatus: authStatus,
            urlBase: Self.awAPIURL,
            context: persistenceController.container.viewContext
        )
    }

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
                // Injects the long-lived, network-backed product repository.
                // It shares this AuthStatus instance with the root UI.
                    .environment(\.productRepository, productRepository)
                    .environment(\.customerOrderRepository, customerOrderRepository)
                    .environment(\.inventoryRepository, inventoryRepository)
                    .environment(\.employeeRepository, employeeRepository)
                // Separate from the custom repository key above,
                // environmentObject() is how @EnvironmentObject-
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
