//
//  AccountView.swift
//  AdventureWorksMobile
//
import SwiftUI

struct AccountView: View {
    
    @EnvironmentObject var authStatus: AuthStatus
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        // Shown as a sheet from the account button on every page, so no account button here.
        PageTemplate("Account", showsScrollToTop: false, showsAccountButton: false) {
            Button("Log out") {
                // Clears both tokens, which sends the app back to LoginView.
                authStatus.logout()
            }
            .accessibilityLabel("Log out")
            .accessibilityHint("Signs out of your account and returns to the sign in screen")
            // Toolbar items set anywhere inside the page land in its nav bar.
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .accessibilityLabel("Done")
                        .accessibilityHint("Closes account settings")
                }
            }
        }
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    AccountView()
        .environmentObject(AuthStatus())
}
