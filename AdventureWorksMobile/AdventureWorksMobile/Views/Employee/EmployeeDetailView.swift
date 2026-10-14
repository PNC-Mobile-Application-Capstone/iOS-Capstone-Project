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
    
    // Photo bytes for this page. The repository handles caching and Core Data.
//    @State private var photoData: Data?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(employee.firstName) \(employee.lastName)")
                    .font(.default)
                    .padding(5)

                Text(employee.jobTitle)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(employee.department)
                    .padding(5)
                
                Text(employee.hireDate ?? "ERROR")
                    .padding(5)
                
                
                if employee.shift != nil  { Text(employee.shift!).padding(5) }
                
            }
        }
        .padding()
    }

}

#Preview { EmployeeList() }
