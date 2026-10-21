//
//  APIEndpoint.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 10/9/26.
//

import Foundation

/// Every API route the app calls, so URLs are built in one place. Paths match Swagger.
enum APIEndpoint {

    /// Root of every route.
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
        // "let id" pulls the value stored in the case so it can go in the path.
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

    /// Full URL as a String, used by the repository methods.
    var urlString: String {
        Self.baseURL + path
    }

    /// Full URL as a URL, used when building a URLRequest directly.
    var url: URL? {
        URL(string: urlString)
    }
}
