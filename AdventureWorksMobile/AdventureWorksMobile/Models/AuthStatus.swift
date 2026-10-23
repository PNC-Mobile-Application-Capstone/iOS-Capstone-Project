//
//  AuthStatus.swift
//  AdventureWorksMobile
//

import SwiftUI
internal import Combine

/// App-wide login state. Views read it, and it is the only place tokens are saved or cleared.
@MainActor
final class AuthStatus: ObservableObject {

    // Keys used to look the tokens up in SecureTokenManager's Keychain storage.
    private let authKey = "userAccessToken"
    private let refreshKey = "userRefreshToken"
    private let tokenStore: any TokenStoring

    // @Published redraws views when the value changes. private(set) means only this class can set it.
    @Published private(set) var isLoggedIn = false
    @Published private(set) var sessionMessage: String?


    /// On launch, the user counts as logged in if both tokens are in the Keychain.
    init(tokenStore: (any TokenStoring)? = nil) {
        // Tests pass their own store. The app uses the Keychain.
        let tokenStore = tokenStore ?? SecureTokenManager.shared
        self.tokenStore = tokenStore
        let auth = tokenStore.getToken(key: authKey)
        let refresh = tokenStore.getToken(key: refreshKey)

        // True only when both tokens exist and are not empty.
        self.isLoggedIn = !(auth?.isEmpty ?? true) && !(refresh?.isEmpty ?? true)
    }


    // Read tokens from the Keychain each time so they never drift out of sync.
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

        // If either save fails, clear both so no half-saved login is left.
        guard tokenStore.saveToken(accessToken, key: authKey),
              tokenStore.saveToken(refreshToken, key: refreshKey) else {
            tokenStore.deleteToken(key: authKey)
            tokenStore.deleteToken(key: refreshKey)
            withAnimation { isLoggedIn = false }
            return false
        }

        sessionMessage = nil
        withAnimation { isLoggedIn = true }
        return true
    }

    // Clears both tokens. sessionExpired shows a message on the login screen.
    func logout(sessionExpired: Bool = false) {
        tokenStore.deleteToken(key: authKey)
        tokenStore.deleteToken(key: refreshKey)

        sessionMessage = sessionExpired
            ? "Your session expired. Please sign in again."
            : nil

        withAnimation { isLoggedIn = false }
    }
}
