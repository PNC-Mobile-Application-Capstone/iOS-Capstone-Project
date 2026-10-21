//
//  WelcomeView.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 9/20/26.
//

import SwiftUI

// Title view. Only its preview uses it right now.
struct Welcome: View {
    
    
    var body: some View {
        Text("Adventure Works")
            .font(.largeTitle)
            .foregroundStyle(Color(.systemGreen))
            .padding()
    }
}

#Preview {
    Welcome()
}
