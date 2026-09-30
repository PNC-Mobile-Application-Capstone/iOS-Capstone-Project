//
//  NetworkError.swift
//  SwiftUIDemo
//
//  Created by Tyler Swindell on 9/14/26.
//

enum NetworkError: Error {
    case invalidURL
    case noConnection
    case badResponse(statusCode: Int)
    case encodingFailed(underlying: Error)
    case decodingFailed(underlying: Error)
    case unauthorized
    case missingAuthToken
}

extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "The server address is invalid."
        case .noConnection:
            "The network connection is unavailable."
        case .badResponse(let statusCode):
            "The server returned an unexpected response (\(statusCode))."
        case .encodingFailed:
            "The request could not be prepared."
        case .decodingFailed:
            "The server response could not be read."
        case .unauthorized, .missingAuthToken:
            "Your session has expired. Please sign in again."
        }
    }
}
