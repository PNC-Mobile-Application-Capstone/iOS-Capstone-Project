//
//  ProductDetails.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 10/14/26.
//


import SwiftUI

struct EmployeeDetails: View {
    
    @Environment(\.employeeRepository) private var repository

    var employee: EmployeeRow
    

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(employee.displayName)
                    .font(.default)
                    .padding(5)

                Text(employee.jobTitle)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(employee.department)
                    .padding(5)
                
                Text(employee.hireDate ?? "ERROR")
                    .padding(5)
                
                
                // Only show the shift when the API sent one.
                if let shift = employee.shift { Text(shift).padding(5) }
                
            }
        }
        .padding()
    }

}

#Preview { EmployeeList() }
