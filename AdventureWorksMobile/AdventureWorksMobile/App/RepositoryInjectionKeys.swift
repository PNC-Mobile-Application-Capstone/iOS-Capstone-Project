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
// expose \.artistRepository / \.boardMemberRepository as if they were
// built-in environment values like \.colorScheme.

/// Environment key for the Artist repository. `defaultValue` is what any
/// view sees if nobody has injected a real one via
/// `.environment(\.artistRepository, ...)` (e.g. in SwiftUI previews) --
/// here it falls back to an in-memory mock instead of a real network
/// repository.
struct ProductRepositoryKey: EnvironmentKey {
    static let defaultValue: (any TieredCacheRepositoryProtocol<Product>)? = nil
}
