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
@MainActor
final class AuthStatus: ObservableObject {

    // Keys used to look the tokens up in SecureTokenManager's Keychain storage.
    private let authKey = "userAccessToken"
    private let refreshKey = "userRefreshToken"
    private let tokenStore: any TokenStoring

    // @Published is a property wrapper (from Combine) that turns simple
    // property assignment into a broadcast: every time isLoggedIn changes,
    // ObservableObject automatically fires objectWillChange, and any
    // SwiftUI view reading this value (via @EnvironmentObject/@StateObject)
    // re-renders. `private(set)` means only this class can change the
    // value directly; outside code has to go through logIn or logout.
    @Published private(set) var isLoggedIn = false


    /// On app launch, check the Keychain for both tokens. If they're both
    /// present the user is treated as still logged in (no fresh login
    /// needed) until/unless a request comes back 401 with no valid refresh
    /// token.
    init(tokenStore: any TokenStoring = SecureTokenManager.shared) {
        self.tokenStore = tokenStore
        let auth = tokenStore.getToken(key: authKey)
        let refresh = tokenStore.getToken(key: refreshKey)

        self.isLoggedIn = !(auth?.isEmpty ?? true) && !(refresh?.isEmpty ?? true)
    }


    // Computed properties that read straight from the Keychain each time,
    // rather than caching the token value here in memory. This keeps
    // AuthStatus and SecureTokenManager from drifting out of sync.
    var authToken: String? {
        tokenStore.getToken(key: authKey)
    }
    var refreshToken: String? {
        tokenStore.getToken(key: refreshKey)
    }


    /// Stores a complete token pair before publishing a logged-in state.
    @discardableResult
    func logIn(accessToken: String?, refreshToken: String?) -> Bool {
        guard let accessToken, !accessToken.isEmpty,
              let refreshToken, !refreshToken.isEmpty else {
            logout()
            return false
        }

        guard tokenStore.saveToken(accessToken, key: authKey),
              tokenStore.saveToken(refreshToken, key: refreshKey) else {
            tokenStore.deleteToken(key: authKey)
            tokenStore.deleteToken(key: refreshKey)
            withAnimation { isLoggedIn = false }
            return false
        }

        withAnimation { isLoggedIn = true }
        return true
    }

    func logout() {
        tokenStore.deleteToken(key: authKey)
        tokenStore.deleteToken(key: refreshKey)
        withAnimation { isLoggedIn = false }
    }
}
