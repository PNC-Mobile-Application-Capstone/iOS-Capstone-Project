//
//  AccountView.swift
//  AdventureWorksMobile
//
import SwiftUI

struct AccountView: View {
    
    @EnvironmentObject var authStatus: AuthStatus
    
    var body: some View {
        PageTemplate("Account") {
            Button("Log out") {
                // Clears both tokens, which sends the app back to LoginView.
                authStatus.logout()
            }
        }
    }
}

#Preview {
    AccountView()
        .environmentObject(AuthStatus())
}
