//
//  TieredCacheRepositoryBase+ProductPhoto.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 10/9/26.
//

import Foundation
import CryptoKit
internal import CoreData

/// The list endpoint has no photo, so the photo comes from the detail
/// endpoint. This decodes only the photo field from that response.
private struct ProductPhotoResponse: Decodable {
    let photo: Data?
}

/// Spots the API's default "No Image Available" picture.
///
/// The AdventureWorks database links many products to one shared
/// placeholder photo. The API sends it like a real photo, so the app
/// can't tell from the field alone. Every copy has the same bytes, so
/// we compare a SHA-256 fingerprint instead. When it matches, we treat
/// the product as having no photo and the view shows our own fallback.
enum ProductPhotoPlaceholder {

    /// SHA-256 hex of the API's placeholder image.
    /// To fill this in: run a Debug build, open a product that shows
    /// "No Image Available" (for example #863), and copy the hash
    /// printed in the Xcode console.
    static let knownHashes: Set<String> = [
        // "paste-hash-here",
    ]

    static func sha256(of data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    static func isPlaceholder(_ data: Data) -> Bool {
        let hash = sha256(of: data)
        #if DEBUG
        print("Product photo SHA-256: \(hash)")
        #endif
        return knownHashes.contains(hash)
    }
}

/// Photo loading for the product repository.
///
/// `where Item == Product` means this method only exists on
/// `TieredCacheRepositoryBase<Product>`. Other repositories, like
/// Inventory or Employee, never see it.
extension TieredCacheRepositoryBase where Item == Product {

    /// Returns the product's photo bytes. Uses the copy saved in Core Data
    /// if there is one. Otherwise it downloads the photo from the detail
    /// endpoint and saves it, so the next visit skips the network call.
    ///
    /// Returns nil when the API only has its "No Image Available"
    /// placeholder, so the view can show the app's own fallback.
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
