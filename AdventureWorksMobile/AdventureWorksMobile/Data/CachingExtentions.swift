//
//  CachingExtentions.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 9/20/26.
//

// Thrown when decoding or caching runs without a Core Data context.
enum DecoderConfigurationError: Error {
    case missingManagedObjectContext
}

enum CachingConfigurationError: Error {
    case missingManagedObjectContext
}

// Key used to hand the Core Data context to the decoder through userInfo.
extension CodingUserInfoKey {
    static let managedObjectContext = CodingUserInfoKey(rawValue: "managedObjectContext")!
}
