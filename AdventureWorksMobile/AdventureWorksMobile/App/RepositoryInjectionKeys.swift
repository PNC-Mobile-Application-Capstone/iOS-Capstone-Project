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
