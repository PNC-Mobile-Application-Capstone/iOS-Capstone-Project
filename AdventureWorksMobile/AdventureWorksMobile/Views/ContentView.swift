//
//  ContentView.swift
//  AdventureWorksMobile
//
//  Created by Nathan Bergman on 9/20/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authStatus: AuthStatus

    // @State is SwiftUI's property wrapper for view-local, mutable state:
    // changing `current` automatically triggers a re-render of this view's body.
    @State private var current: String = ""


    var body: some View {
        NavigationStack {
            VStack {
                // Simple screen router: `current` picks which feature
                // screen to show, each wired up with the repository that
                // was injected via @Environment above.
                switch current {
                case "home":
                    Welcome()
                        .accessibilityIdentifier("welcomeView")
                case "products":
                    ProductList()
                        .accessibilityIdentifier("productView")
                case "dashboard":
                    DashboardView(repository:MockDashboardRepository())
                        .accessibilityIdentifier("productView")
                default:
                    Welcome()
                        .accessibilityIdentifier("welcomeView")
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Home") {
                            current = "home"
                        }
                        .accessibilityIdentifier("homeViewButton")
                        Button("Dashboard") {
                            current = "dashboard"
                        }
                        .accessibilityIdentifier("productsViewButton")
                        Button("Products") {
                            current = "products"
                        }
                        .accessibilityIdentifier("productsViewButton")
                        Divider()
                        Button("Log out") {
                            // Clears both Keychain tokens and sets isLoggedIn to false,
                            // which sends the app back to LoginView.
                            authStatus.logout()
                        }
                        .accessibilityIdentifier("logoutButton")
                    }
                    label: { Label("View", systemImage: "line.3.horizontal") }
                    .accessibilityIdentifier("mainMenuButton")
                }
            }
        }
        
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthStatus())
}
