//
//  ContentView.swift
//  AdventureWorksMobile
//
//  Created by Nathan Bergman on 9/20/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authStatus: AuthStatus
    
    var body: some View {
        TabView {
            DashboardView(repository: RemoteDashboardRepository(authStatus: authStatus))
                .accessibilityIdentifier("dashboardView")
                .tabItem { Label("Dashboard", systemImage: "house.fill") }
            
            ProductList()
                .accessibilityIdentifier("productView")
                .tabItem { Label("Products", systemImage: "shippingbox.fill") }
            
            CustomerOrderList()
                .accessibilityIdentifier("customerOrderView")
                .tabItem { Label("Orders", systemImage: "list.bullet.circle.fill") }
            
            EmployeeList()
                .accessibilityIdentifier("employeeListView")
                .tabItem { Label("Employees", systemImage: "person.3.fill") }
            
            AccountView()
                .accessibilityIdentifier("accountView")
                .tabItem { Label("Account", systemImage: "person.crop.circle")}
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthStatus())
}
