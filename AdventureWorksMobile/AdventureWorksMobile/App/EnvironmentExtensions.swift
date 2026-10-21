//
//  EnvExt.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 9/20/26.
//

import SwiftUI

// Turns each EnvironmentKey into a \.name property that views read with @Environment.
extension EnvironmentValues {

    /// Lets a view use @Environment(\.productRepository) instead of a hardcoded type.
    var productRepository: (any TieredCacheRepositoryProtocol<Product>)? {
        // get and set read and write the value stored under the key.
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
