//
//  CachingExtentions.swift
//  SwiftUIDemo
//
//  Created by Tyler Swindell on 9/18/26.
//

enum DecoderConfigurationError: Error {
    case missingManagedObjectContext
}

enum CachingConfigurationError: Error {
    case missingManagedObjectContext
}

extension CodingUserInfoKey {
    static let managedObjectContext = CodingUserInfoKey(rawValue: "managedObjectContext")!
}
