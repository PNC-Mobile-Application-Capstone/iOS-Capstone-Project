//
//  ContentView.swift
//  AdventureWorksMobile
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authStatus: AuthStatus
    
    var body: some View {
        // One tab per screen. Each screen loads its own data.
        // Keep this at 5 tabs. On iPhone a 6th tab sends the last ones under "More",
        // which has its own nav bar and doubles the back button.
        // Account opens from the button at the top right of each page instead.
        TabView {
            // The dashboard gets its repository here instead of from the environment.
            DashboardView(repository: RemoteDashboardRepository(authStatus: authStatus))
                .accessibilityIdentifier("dashboardView")
                .tabItem { Label("Dashboard", systemImage: "house.fill") }
            
            ProductList()
                .accessibilityIdentifier("productView")
                .tabItem { Label("Products", systemImage: "shippingbox.fill") }
            
            InventoryList()
                .accessibilityIdentifier("inventoryView")
                .tabItem { Label("Inventory", systemImage: "archivebox.fill") }
            
            CustomerOrderList()
                .accessibilityIdentifier("customerOrderView")
                .tabItem { Label("Orders", systemImage: "list.bullet.circle.fill") }
            
            EmployeeList()
                .accessibilityIdentifier("employeeListView")
                .tabItem { Label("Employees", systemImage: "person.3.fill") }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthStatus())
}
