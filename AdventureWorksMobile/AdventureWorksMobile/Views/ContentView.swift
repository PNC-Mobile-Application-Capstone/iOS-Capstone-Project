//
//  ContentView.swift
//  AdventureWorksMobile
//
//  Created by Nathan Bergman on 9/20/26.
//

import SwiftUI

struct ContentView: View {
    // @EnvironmentObject, unlike @Environment, looks up an ObservableObject
    // by its type rather than by a key, matching the plain
    // .environmentObject(authStatus) call in SwiftUIDemoApp.
    @EnvironmentObject var authStatus: AuthStatus
    
    // @State is SwiftUI's property wrapper for view-local, mutable state:
    // changing `current` automatically triggers a re-render of this view's body.
    @State private var current: String = ""
    
    var body: some View {
        TabView {
            DashboardView(repository: MockDashboardRepository())
                .accessibilityIdentifier("dashboardView")
                .tabItem { Label("Dashboard", systemImage: "house.fill") }
            
            ProductList()
                .accessibilityIdentifier("productView")
                .tabItem { Label("Products", systemImage: "shippingbox.fill") }
            
            AccountView()
                .accessibilityIdentifier("accountView")
                .tabItem { Label("Account", systemImage: "person.crop.circle")}
            
            // Add employee list and order list when theyre ready
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthStatus())
}
