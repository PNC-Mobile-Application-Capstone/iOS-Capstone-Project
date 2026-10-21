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

    // @StateObject creates AuthStatus once at launch and keeps it alive while the app runs.
    @StateObject private var authStatus: AuthStatus
    private let persistenceController: PersistenceController
    // Each repository is the same generic class pointed at a different endpoint.
    private let productRepository: TieredCacheRepositoryBase<Product>
    private let customerOrderRepository: TieredCacheRepositoryBase<CustomerOrder>
    private let inventoryRepository: TieredCacheRepositoryBase<Inventory>
    private let employeeRepository: TieredCacheRepositoryBase<Employee>

    init() {
        let authStatus = AuthStatus()
        // UI tests pass this launch flag to start signed out.
        if ProcessInfo.processInfo.arguments.contains("--ui-testing-reset-auth") {
            authStatus.logout()
        }
        let persistenceController = PersistenceController.shared
        // The underscore sets the @StateObject wrapper itself, which is how you fill one in init.
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
            // Show the tabs when signed in, or the login screen when not.
            if authStatus.isLoggedIn {
                ContentView()
                // Give every view the Core Data context.
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                // Inject the repositories so views can read them with @Environment(\.productRepository).
                    .environment(\.productRepository, productRepository)
                    .environment(\.customerOrderRepository, customerOrderRepository)
                    .environment(\.inventoryRepository, inventoryRepository)
                    .environment(\.employeeRepository, employeeRepository)
                // environmentObject() hands AuthStatus to @EnvironmentObject properties by type.
                    .environmentObject(authStatus)
            }
            else {
                LoginView()
                    .environmentObject(authStatus)
            }
        }
    }
}
