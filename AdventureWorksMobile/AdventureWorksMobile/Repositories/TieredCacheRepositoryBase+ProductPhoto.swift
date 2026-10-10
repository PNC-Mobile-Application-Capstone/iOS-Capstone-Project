//
//  TieredCacheRepositoryBase+ProductPhoto.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 10/9/26.
//

import Foundation
internal import CoreData

/// The list endpoint has no photo, so the photo comes from the detail
/// endpoint. This decodes only the photo field from that response.
private struct ProductPhotoResponse: Decodable {
    let photo: Data?
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
    func loadPhoto(for product: Product) async throws -> Data? {
        if let cached = product.photo { return cached }

        let response = try await fetchDecoded("\(urlBase)/\(product.id)",
                                              as: ProductPhotoResponse.self)

        if let photo = response.photo {
            product.photo = photo
            try product.managedObjectContext?.save()
        }
        return response.photo
    }
}
