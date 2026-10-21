//
//  SecureTokenManager.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 9/25/26.
//

import Foundation
import Security

// Token storage. The app uses the Keychain and tests use an in-memory version.
protocol TokenStoring {
    @discardableResult
    func saveToken(_ token: String, key: String) -> Bool
    func getToken(key: String) -> String?
    func deleteToken(key: String)
}

/// Saves, reads, and deletes tokens in the Keychain, which is encrypted, unlike UserDefaults.
final class SecureTokenManager: TokenStoring {
    // Singleton, same reasoning as AuthService: one manager, shared everywhere.
    static let shared = SecureTokenManager()

    // private init means everyone has to use .shared.
    private init() {}

    // Groups this app's Keychain items. Each key names one item inside it.
    private let service = "com.adventure-works-mobile-app.auth"

    /// Saves a token under key. Returns true on success.
    func saveToken(_ token: String, key: String) -> Bool {
        // Keychain APIs work with raw Data, not String, so convert first.
        guard let data = token.data(using: .utf8) else { return false }

        // Keychain calls take a dictionary that describes the item.
        let lookupQuery: [String: Any] = [
            // Generic password is the plain key/value item type.
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            // Readable after the first unlock since boot, on this device only.
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        // Delete any old item first so the add does not fail as a duplicate.
        SecItemDelete(lookupQuery as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)

        return status == errSecSuccess
    }

    /// Returns the token saved under key, or nil.
    func getToken(key: String) -> String? {

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            // Return the stored data, not just whether it exists.
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        // SecItemCopyMatching writes the result into dataRef through the & pointer.
        var dataRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataRef)

        if status == errSecSuccess, let data = dataRef as? Data {
            return String(data: data, encoding: .utf8)
        }

        return nil
    }

    /// Deletes the token saved under key, if there is one.
    func deleteToken(key: String) {

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}
