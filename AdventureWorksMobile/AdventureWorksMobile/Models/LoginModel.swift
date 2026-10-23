//
//  LoginModel.swift
//  AdventureWorksMobile
//

import Foundation

/// Request body for POST /api/Login.
struct LoginModel: Codable {

    var username: String = ""
    var password: String = ""

    // The API wants "loginId", so remap username. Once CodingKeys exists, every key must be listed.
    enum CodingKeys: String, CodingKey {
        case username = "loginId"
        case password
    }
}
