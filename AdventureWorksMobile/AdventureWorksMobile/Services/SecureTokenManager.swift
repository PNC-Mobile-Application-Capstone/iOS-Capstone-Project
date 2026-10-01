//
//  SecureTokenManager.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 9/25/26.
//

import Foundation
import Security

protocol TokenStoring {
    @discardableResult
    func saveToken(_ token: String, key: String) -> Bool
    func getToken(key: String) -> String?
    func deleteToken(key: String)
}

/// A thin wrapper around the iOS/macOS Keychain (the `Security` framework's
/// C APIs) for saving, reading, and deleting auth tokens.
///
/// Tokens should never be stored in UserDefaults or a plain file since
/// those aren't encrypted at rest. The Keychain is, so this is where the
/// access token and refresh token both live between app launches.
final class SecureTokenManager: TokenStoring {
    // Singleton, same reasoning as AuthService: one manager, shared everywhere.
    static let shared = SecureTokenManager()

    private init() {}

    // "service" groups every item this app saves under one Keychain bucket.
    // The "key" parameter on each method below (e.g. "userAccessToken",
    // "userRefreshToken") is what distinguishes individual items within
    // that bucket.
    private let service = "com.adventure-works-mobile-app.auth"

    /// Saves a token string into the Keychain under `key`.
    /// Returns true if the save succeeded.
    func saveToken(_ token: String, key: String) -> Bool {
        // Keychain APIs work with raw Data, not String, so convert first.
        guard let data = token.data(using: .utf8) else { return false }

        // Keychain calls are dictionary-based ("query") rather than having
        // dedicated method signatures. This query describes what we're
        // saving and where.
        let lookupQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,   // generic key/value item (vs. a certificate, internet password, etc.)
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            // Item is unlocked (readable) once the user has unlocked the
            // device for the first time after boot, and stays that way
            // even if the device is locked again. Good default for tokens
            // that background refresh logic may need to read.
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        // delete any existing item (for this key) before saving,
        // to prevent duplicate value conflicts
        SecItemDelete(lookupQuery as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)

        return status == errSecSuccess
    }

    /// Reads back the token string stored under `key`, or nil if nothing
    /// is saved (or the read failed).
    func getToken(key: String) -> String? {

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,        // ask the Keychain to hand back the actual data, not just confirm it exists
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataRef)

        if status == errSecSuccess, let data = dataRef as? Data {
            return String(data: data, encoding: .utf8)
        }

        return nil
    }

    /// Removes the token stored under `key`, if any. Used on logout, or
    /// when a caller needs to clear a token that's no longer valid.
    func deleteToken(key: String) {

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}
