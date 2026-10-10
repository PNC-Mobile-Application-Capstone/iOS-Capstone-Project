//
//  LoginResponse.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 9/20/26.
//

import Foundation

/// What the API sends back from both POST /api/Login and
/// POST /api/Login/refresh. `accessToken`/`refreshToken` are optional
/// because a failed login (success == false) may return a body with no
/// tokens in it.
struct LoginResponse: Codable {
    var success: Bool
    var userName: String?
    var accessToken: String?
    var refreshToken: String?
    var accessExpiry: Date?
    var refreshExpiry: Date?

    // Maps the API's expiry field names to friendlier Swift property
    // names. The other fields don't need remapping here (the decoder's
    // .convertFromSnakeCase strategy, set where this is decoded, handles
    // straightforward snake_case -> camelCase conversions on its own),
    // but they still have to be listed since defining CodingKeys at all
    // means only the cases you list get encoded/decoded.
    enum CodingKeys: String, CodingKey {
        case success, userName, accessToken, refreshToken
        case accessExpiry = "accessTokenExpiresAtUtc"
        case refreshExpiry = "refreshTokenExpiresAtUtc"
    }

}
