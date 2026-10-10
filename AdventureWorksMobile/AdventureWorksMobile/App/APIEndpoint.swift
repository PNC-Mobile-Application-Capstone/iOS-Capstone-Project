//
//  APIEndpoint.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 10/9/26.
//

import Foundation

/// Every AdventureWorks API route the app calls, in one place.
///
/// Repositories and services ask this enum for a URL instead of
/// building strings by hand. If the server address or a path ever
/// changes, this is the only file that needs to change.
///
/// Paths match the casing shown in Swagger
/// (https://api.bootcampcentral.com/swagger/index.html).
enum APIEndpoint {

    /// Root of every route. Change this to point the app at a
    /// different server.
    static let baseURL = "https://api.bootcampcentral.com/api"

    // Auth

    /// POST. Signs in and returns the access and refresh tokens.
    case login
    /// POST. Trades a refresh token for a new access token.
    case refreshToken

    // Dashboard

    case weeklySales
    case bestWorstProducts
    case lowStock
    case shifts

    // Employees

    case employees
    case employee(id: Int)
    /// PUT. Updates an employee's personal info.
    case employeePersonalInfo(id: Int)
    /// PUT. Updates an employee's employment info.
    case employeeEmploymentInfo(id: Int)

    // Products

    case products
    case product(id: Int)

    // MARK: - Inventory

    case inventory
    /// PUT. Adjusts stock for one product at one location.
    case inventoryItem(productId: Int, locationId: Int)

    // MARK: - Orders

    case customerOrders
    case customerOrder(id: Int)

    // MARK: - Lookups

    case departments
    case shiftTypes

    // MARK: - Building the URL

    /// The route after the base URL, starting with a slash.
    var path: String {
        switch self {
        case .login:
            "/Login"
        case .refreshToken:
            "/Login/refresh"

        case .weeklySales:
            "/Dashboard/weekly-sales"
        case .bestWorstProducts:
            "/Dashboard/best-worst"
        case .lowStock:
            "/Dashboard/low-stock"
        case .shifts:
            "/Dashboard/shifts"

        case .employees:
            "/Employee"
        case .employee(let id):
            "/Employee/\(id)"
        case .employeePersonalInfo(let id):
            "/Employee/personal/\(id)"
        case .employeeEmploymentInfo(let id):
            "/Employee/employment/\(id)"

        case .products:
            "/Product"
        case .product(let id):
            "/Product/\(id)"

        case .inventory:
            "/Inventory"
        case .inventoryItem(let productId, let locationId):
            "/Inventory/\(productId)/\(locationId)"

        case .customerOrders:
            "/Order/customer"
        case .customerOrder(let id):
            "/Order/customer/\(id)"

        case .departments:
            "/Department"
        case .shiftTypes:
            "/Shift"
        }
    }

    /// The full URL as a string. Use this with the repository methods,
    /// which take a String (fetchAll, fetchOne, put, and so on).
    var urlString: String {
        Self.baseURL + path
    }

    /// The full URL as a URL. Use this when building a URLRequest
    /// directly, like AuthService does.
    var url: URL? {
        URL(string: urlString)
    }
}
