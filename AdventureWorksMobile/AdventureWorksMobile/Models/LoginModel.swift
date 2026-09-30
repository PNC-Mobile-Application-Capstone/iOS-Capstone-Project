//
//  LoginModel.swift
//  SwiftUIDemo
//
//  Created by Tyler Swindell on 9/15/26.
//

import Foundation

/// The request body sent to POST /api/Login. Conforms to Codable so
/// AuthService can hand it straight to JSONEncoder.
struct LoginModel: Codable {

    var username: String = ""
    var password: String = ""

    // CodingKeys lets the JSON key differ from the Swift property name.
    // The API expects "loginId" instead of "username", so this remaps
    // just that one field; "password" is listed as-is because it needs no
    // remapping but still has to be included once CodingKeys is defined at
    // all (otherwise only the keys you list would be encoded/decoded, and
    // password would be silently dropped).
    enum CodingKeys: String, CodingKey {
        case username = "loginId"
        case password
    }
}
