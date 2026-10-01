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
                        Button("Products") {
                            current = "products"
                        }
                        .accessibilityIdentifier("productsViewButton")
                        Divider()
                        Button("Log out") {
                            // Clears isLoggedIn (and, inside
                            // updateLoginStatus, both Keychain tokens since
                            // no authToken/refreshToken args are passed
                            // here), which flips SwiftUIDemoApp back to
                            // showing LoginView.
                            authStatus.updateLoginStatus(success: false)
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
}
