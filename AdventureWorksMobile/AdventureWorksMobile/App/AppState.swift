//
//  AppState.swift
//  
//
//  Created by Nathan Bergman on 9/20/26.
//

import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var isLoggedIn = false

    func login() {
        withAnimation {
            isLoggedIn = true
        }
    }

    func logout() {
        withAnimation {
            isLoggedIn = false
        }
    }
    
}
