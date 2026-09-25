//
//  ContentView.swift
//  AdventureWorksMobile
//
//  Created by Nathan Bergman on 9/20/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        
        if appState.isLoggedIn {
            MainView()
        }else
        {
            LoginView()
        }
    }
}


#Preview {
    ContentView().environmentObject(AppState())
}
