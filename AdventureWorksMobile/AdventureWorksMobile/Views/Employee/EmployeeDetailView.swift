//
//  EmployeeDetailView.swift
//  AdventureWorksMobile
//


import SwiftUI

struct EmployeeDetails: View {
    
    @Environment(\.employeeRepository) private var repository

    var employee: EmployeeRow
    

    var body: some View {
        // ScrollView keeps the content at the top and lets long pages scroll.
        ScrollView {
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle(employee.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

}

#Preview { EmployeeList() }
