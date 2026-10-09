//
//  EnvExt.swift
//  SwiftUIDemo
//
//  Created by Tyler Swindell on 9/11/26.
//

import SwiftUI

// Extending EnvironmentValues is what turns the EnvironmentKeys defined in
// RepoInjectionKeys.swift into dot-syntax properties (\.productRepository)
// that read like any other SwiftUI environment value. This is the
// standard pattern for custom dependency injection in SwiftUI: define a
// key + default value, then expose it here as a computed property whose
// get/set just reads and writes through the key's subscript.
extension EnvironmentValues {

    /// Lets any view do `@Environment(\.artistRepository) var artistRepository`
    /// to receive whichever repository was injected higher up the view
    /// tree (a real RemoteArtistRepository in the live app,
    /// MockArtistRepository in previews/tests), instead of hardcoding a
    /// concrete type.
    var productRepository: (any TieredCacheRepositoryProtocol<Product>)? {
        get { self[ProductRepositoryKey.self] }
        set { self[ProductRepositoryKey.self] = newValue }
    }

    var customerOrderRepository: (any TieredCacheRepositoryProtocol<CustomerOrder>)? {
        get { self[CustomerOrderRepositoryKey.self] }
        set { self[CustomerOrderRepositoryKey.self] = newValue }
    }

    var inventoryRepository: (any TieredCacheRepositoryProtocol<Inventory>)? {
        get { self[InventoryRepositoryKey.self] }
        set { self[InventoryRepositoryKey.self] = newValue }
    }

    var employeeRepository: (any TieredCacheRepositoryProtocol<Employee>)? {
        get { self[EmployeeRepositoryKey.self] }
        set { self[EmployeeRepositoryKey.self] = newValue }
    }
}
