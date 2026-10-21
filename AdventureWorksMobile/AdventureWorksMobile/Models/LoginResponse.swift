//
//  LoginResponse.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 9/20/26.
//

import Foundation

/// Response from login and refresh. Tokens are optional because a failed login has none.
struct LoginResponse: Codable {
    var success: Bool
    var userName: String?
    var accessToken: String?
    var refreshToken: String?
    var accessExpiry: Date?
    var refreshExpiry: Date?

    // Rename the expiry fields. The rest are listed because CodingKeys must include every key.
    enum CodingKeys: String, CodingKey {
        case success, userName, accessToken, refreshToken
        case accessExpiry = "accessTokenExpiresAtUtc"
        case refreshExpiry = "refreshTokenExpiresAtUtc"
    }

}
