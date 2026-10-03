//
//  TieredCacheProductRepository.swift
//  SwiftUIDemo
//
//  Created by Tyler Swindell on 9/18/26.
//
internal import CoreData

class TieredCacheProductRepository: TieredCacheRepositoryBase<Product> {

    private let productURL: String

    override init(authStatus: AuthStatus,
                  urlBase: String,
                  context: NSManagedObjectContext,
                  session: URLSession = .shared,
                  authService: any AuthServicing = AuthService.shared,
                  defaults: UserDefaults = .standard,
                  now: @escaping () -> Date = Date.init) {
        let url = "\(urlBase)/product"
        self.productURL = url
        super.init(authStatus: authStatus,
                   urlBase: url,
                   context: context,
                   session: session,
                   authService: authService,
                   defaults: defaults,
                   now: now)
    }

    // The list endpoint has no photo, so get it from the detail endpoint.
    private struct PhotoResponse: Decodable {
        let photo: Data?
    }

    /// Returns the product's photo bytes. Uses the copy saved in Core Data
    /// if there is one. Otherwise it downloads the photo from the detail
    /// endpoint and saves it, so the next visit skips the network call.
    func loadPhoto(for product: Product) async throws -> Data? {
        if let cached = product.photo {
            return cached
        }

        let response = try await fetchDecoded("\(productURL)/\(product.id)", as: PhotoResponse.self)

        if let photo = response.photo {
            product.photo = photo
            try product.managedObjectContext?.save()
        }
        return response.photo
    }
}
