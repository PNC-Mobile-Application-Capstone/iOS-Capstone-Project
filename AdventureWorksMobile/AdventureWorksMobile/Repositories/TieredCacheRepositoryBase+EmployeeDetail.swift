//
//  TieredCacheRepositoryBase+EmployeeDetail.swift
//  AdventureWorksMobile
//

import Foundation
internal import CoreData

extension TieredCacheRepositoryBase where Item == Employee {
    func loadDetail(for employeeId: Int64) async throws -> EmployeeDetail {
        try await fetchDecoded("\(urlBase)/\(employeeId)", as: EmployeeDetail.self)
    }
}
