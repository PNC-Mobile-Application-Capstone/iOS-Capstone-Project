//
//  RepositoryInjectionKeys.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 9/27/26.
//

import SwiftUI

// One EnvironmentKey per repository. EnvironmentExtensions.swift turns these into \.name properties.

/// Product repository key. Nil by default so previews never call the live API.
struct ProductRepositoryKey: EnvironmentKey {
    static let defaultValue: (any TieredCacheRepositoryProtocol<Product>)? = nil
}

/// Environment key for the customer order repository.
struct CustomerOrderRepositoryKey: EnvironmentKey {
    static let defaultValue: (any TieredCacheRepositoryProtocol<CustomerOrder>)? = nil
}

/// Environment key for the inventory repository.
struct InventoryRepositoryKey: EnvironmentKey {
    static let defaultValue: (any TieredCacheRepositoryProtocol<Inventory>)? = nil
}

/// Environment key for the employee repository.
struct EmployeeRepositoryKey: EnvironmentKey {
    static let defaultValue: (any TieredCacheRepositoryProtocol<Employee>)? = nil
}
