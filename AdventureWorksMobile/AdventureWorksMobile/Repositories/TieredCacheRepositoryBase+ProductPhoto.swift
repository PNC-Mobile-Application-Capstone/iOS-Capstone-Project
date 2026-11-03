//
//  TieredCacheRepositoryBase+ProductPhoto.swift
//  AdventureWorksMobile
//

import Foundation
import CryptoKit
internal import CoreData

/// Decodes only the photo field from the product detail response.
private struct ProductPhotoResponse: Decodable {
    let photo: Data?
}

/// Spots the API's shared "No Image Available" photo by its SHA-256 hash.
enum ProductPhotoPlaceholder {

    /// Placeholder hashes. Run a Debug build, open a product with no image (like #863), and copy the printed hash.
    static let knownHashes: Set<String> = [
        // "paste-hash-here",
    ]

    static func sha256(of data: Data) -> String {
        // Turn each hash byte into two hex characters and join them.
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    static func isPlaceholder(_ data: Data) -> Bool {
        let hash = sha256(of: data)
        // Only print the hash in Debug builds.
        #if DEBUG
        print("Product photo SHA-256: \(hash)")
        #endif
        return knownHashes.contains(hash)
    }
}

/// Photo loading. "where Item == Product" means only the product repository gets this.
extension TieredCacheRepositoryBase where Item == Product {

    /// Returns the photo from Core Data, or downloads and saves it. Nil if it is the placeholder.
    func loadPhoto(for product: Product) async throws -> Data? {
        if let cached = product.photo {
            // Older caches may still hold the placeholder. Filter it here too.
            return ProductPhotoPlaceholder.isPlaceholder(cached) ? nil : cached
        }

        let response = try await fetchDecoded("\(urlBase)/\(product.id)",
                                              as: ProductPhotoResponse.self)

        // Still cache the bytes so we skip the network next time.
        if let photo = response.photo {
            product.photo = photo
            try product.managedObjectContext?.save()
        }

        guard let photo = response.photo,
              !ProductPhotoPlaceholder.isPlaceholder(photo) else { return nil }
        return photo
    }
}
