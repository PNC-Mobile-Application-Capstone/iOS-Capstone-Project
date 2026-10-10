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
    // Every repository uses the generic base class with its own endpoint.
    // Product photo loading lives in TieredCacheRepositoryBase+ProductPhoto.
    private let productRepository: TieredCacheRepositoryBase<Product>
    private let customerOrderRepository: TieredCacheRepositoryBase<CustomerOrder>
    private let inventoryRepository: TieredCacheRepositoryBase<Inventory>
    private let employeeRepository: TieredCacheRepositoryBase<Employee>

    init() {
        let authStatus = AuthStatus()
        if ProcessInfo.processInfo.arguments.contains("--ui-testing-reset-auth") {
            authStatus.logout()
        }
        let persistenceController = PersistenceController.shared
        _authStatus = StateObject(wrappedValue: authStatus)
        self.persistenceController = persistenceController
        // GET /api/Product
        self.productRepository = TieredCacheRepositoryBase<Product>(
            authStatus: authStatus,
            urlBase: APIEndpoint.products.urlString,
            context: persistenceController.container.viewContext
        )
        // GET /api/Order/customer
        self.customerOrderRepository = TieredCacheRepositoryBase<CustomerOrder>(
            authStatus: authStatus,
            urlBase: APIEndpoint.customerOrders.urlString,
            context: persistenceController.container.viewContext
        )
        // GET /api/Inventory
        self.inventoryRepository = TieredCacheRepositoryBase<Inventory>(
            authStatus: authStatus,
            urlBase: APIEndpoint.inventory.urlString,
            context: persistenceController.container.viewContext
        )
        // GET /api/Employee
        self.employeeRepository = TieredCacheRepositoryBase<Employee>(
            authStatus: authStatus,
            urlBase: APIEndpoint.employees.urlString,
            context: persistenceController.container.viewContext
        )
    }

    var body: some Scene {
        WindowGroup {
            // Whether the user sees the logged-in app or the login screen
            // is decided by AuthStatus.isLoggedIn, which was
            // itself seeded from whatever tokens were found in the
            // Keychain when AuthStatus was created above.
            if authStatus.isLoggedIn {
                ContentView()
                // configure custom dependency injection
                // Makes Core Data's main-thread context available to
                // any view via @Environment(\.managedObjectContext, ...).
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                // Injects the project repositories.
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
