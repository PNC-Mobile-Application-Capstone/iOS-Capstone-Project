//
//  WelcomeView.swift
//  SwiftUIDemo
//
//  Created by Tyler Swindell on 9/14/26.
//

import SwiftUI

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
