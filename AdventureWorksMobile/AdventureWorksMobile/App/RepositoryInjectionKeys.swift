//
//  RepositoryInjectionKeys.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 9/27/26.
//

import SwiftUI

// SwiftUI's environment doesn't let you inject arbitrary values by type
// alone (the way @EnvironmentObject does for ObservableObjects); each
// custom value needs a key type conforming to EnvironmentKey. This file
// defines one key per repository. EnvExt.swift then uses these keys to
// expose \.productRepository as if it were
// built-in environment values like \.colorScheme.

/// Environment key for the product repository. A nil default keeps previews
/// from contacting the live API when no repository is explicitly injected.
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
