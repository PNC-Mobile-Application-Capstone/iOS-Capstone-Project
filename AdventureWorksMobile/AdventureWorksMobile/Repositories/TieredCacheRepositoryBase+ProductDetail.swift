//
//  TieredCacheRepositoryBase+ProductDetail.swift
//  AdventureWorksMobile
//

import Foundation
internal import CoreData

private struct ProductDetailResponse: Decodable {
    let productName: String?
    let productNumber: String?
    let summary: String?
    let photo: Data?
    let photoFileName: String?
    let color: String?
    let listPrice: Double?
    let productLine: String?
    let productModelId: Int64?
    let productModelName: String?
    let wheelDescription: String?
    let saddleDescription: String?
    let pedalDescription: String?
    let riderExperience: String?
    let manufacturer: String?
    let bikeFrame: String?
    let crankset: String?
    let material: String?
    let style: String?
    let warrantyPeriod: String?
    let warrantyDescription: String?
    let maintenanceDescription: String?
    let numberOfSteps: Int64?
    let setupHours: Double?
    let machineHours: Double?
    let laborHours: Double?
    let lotSize: Int64?
}

private let productDetailMaxAge: TimeInterval = 15 * 60

extension TieredCacheRepositoryBase where Item == Product {
    
    func loadDetail(for product: Product, forceRefresh: Bool = false) async throws {
        if !forceRefresh,
           let savedAt = product.detailUpdatedAt,
           Date().timeIntervalSince(savedAt) <= productDetailMaxAge {
            return
        }
        
        let response = try await fetchDecoded("\(urlBase)/\(product.id)", as: ProductDetailResponse.self)
        
        guard let context = product.managedObjectContext, !product.isDeleted else { return }
        
        if let name = response.productName { product.name = name }
        if let num = response.productNumber { product.productNumber = num }
        if let price = response.listPrice { product.listPrice = price }
        product.color = response.color
        
        if let photo = response.photo { product.photo = photo }
        product.photoFileName = response.photoFileName
        
        product.summary = response.summary
        product.productLine = response.productLine?.trimmingCharacters(in: .whitespaces)
        product.productModelId = response.productModelId ?? 0
        product.productModelName = response.productModelName
        product.wheelDescription = response.wheelDescription
        product.saddleDescription = response.saddleDescription
        product.pedalDescription = response.pedalDescription
        product.riderExperience = response.riderExperience
        product.manufacturer = response.manufacturer
        product.bikeFrame = response.bikeFrame
        product.crankset = response.crankset
        product.material = response.material
        product.style = response.style
        product.warrantyPeriod = response.warrantyPeriod
        product.warrantyDescription = response.warrantyDescription
        product.maintenanceDescription = response.maintenanceDescription
        product.numberOfSteps = response.numberOfSteps ?? 0
        product.setupHours = response.setupHours ?? 0
        product.machineHours = response.machineHours ?? 0
        product.laborHours = response.laborHours ?? 0
        product.lotSize = response.lotSize ?? 0
        
        product.detailUpdatedAt = Date()
        try context.save()
    }
}
