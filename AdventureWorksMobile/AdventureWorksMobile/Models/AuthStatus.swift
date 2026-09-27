//
//  AuthStatus.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 9/25/26.
//

import SwiftUI
internal import Combine

/// Observable app-wide auth state. This is what views check to decide
/// whether to show LoginView or the logged-in ContentView, and it's the
/// single place tokens get written to (or cleared from) the Keychain.
///
/// `internal import Combine` above pulls in the Combine framework, which
/// is where `ObservableObject` and `@Published` come from.
class AuthStatus: ObservableObject {
    
    // Keys used to look the tokens up in SecureTokenManager's Keychain storage.
    private let authKey = "userAccessToken"
    private let refreshKey = "userRefreshToken"
    
    // @Published is a property wrapper (from Combine) that turns simple
    // property assignment into a broadcast: every time isLoggedIn changes,
    // ObservableObject automatically fires objectWillChange, and any
    // SwiftUI view reading this value (via @EnvironmentObject/@StateObject)
    // re-renders. `private(set)` means only this class can change the
    // value directly; outside code has to go through updateLoginStatus(_:).
    @Published private(set) var isLoggedIn = false
    
    
    /// On app launch, check the Keychain for both tokens. If they're both
    /// present the user is treated as still logged in (no fresh login
    /// needed) until/unless a request comes back 401 with no valid refresh
    /// token.
    init() {
        let auth = SecureTokenManager.shared.getToken(key: authKey)
        let refresh = SecureTokenManager.shared.getToken(key: refreshKey)
        
        self.isLoggedIn = auth != nil && refresh != nil
    }
    
    
    // Computed properties that read straight from the Keychain each time,
    // rather than caching the token value here in memory. This keeps
    // AuthStatus and SecureTokenManager from drifting out of sync.
    var authToken: String? {
        return SecureTokenManager.shared.getToken(key: authKey)
    }
    var refreshToken: String? {
        return SecureTokenManager.shared.getToken(key: refreshKey)
    }
    
    
    /// Single entry point for changing login state. Called after a
    /// successful login, after a successful token refresh, and on logout
    /// (success: false, with both token params left as their default "").
    func updateLoginStatus(success: Bool,
                           authToken: String? = "",
                           refreshToken: String? = "") {
        // withAnimation wraps the @Published change so SwiftUI cross-fades
        // between LoginView and ContentView instead of just snapping.
        withAnimation {
            isLoggedIn = success
        }
        
        let storage = SecureTokenManager.shared
        
        // A non-empty token gets saved; an empty/nil one (like the logout
        // default of "") means "clear whatever is currently stored".
        if let auth = authToken, !auth.isEmpty {
            let _ = storage.saveToken(auth, key: authKey)
        } else {
            storage.deleteToken(key: authKey)
        }
        
        if let refresh = refreshToken, !refresh.isEmpty {
            let _ = storage.saveToken(refresh, key: refreshKey)
        } else {
            storage.deleteToken(key: refreshKey)
        }
        
        
    }
    
}

