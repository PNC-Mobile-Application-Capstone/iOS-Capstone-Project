//
//  AccountView.swift
//  AdventureWorksMobile
//
//  Created by user302023 on 10/10/26.
//
import SwiftUI

struct AccountView: View {
    
    @EnvironmentObject var authStatus: AuthStatus
    
    var body: some View {
        NavigationStack {
            List {
                Button("Log out") {
                    // Clears both Keychain tokens and sets isLoggedIn to false,
                    // which sends the app back to LoginView.
                    authStatus.logout()
                }
            }
            .navigationTitle("Account")
        }
    }
}

#Preview {
    AccountView()
        .environmentObject(AuthStatus())
}
