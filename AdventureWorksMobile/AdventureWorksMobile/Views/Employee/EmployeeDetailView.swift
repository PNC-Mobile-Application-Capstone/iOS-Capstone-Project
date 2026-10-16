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
        VStack(alignment: .leading, spacing: 8) {
            Text("\(employee.firstName) \(employee.lastName)")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(5)

            Text(employee.jobTitle)
                .font(.title)
                .padding(5)

            Text("\(employee.shift != nil ? "\(employee.shift!) shift in the" : "") \(employee.department) Department")
                .padding(5)
            
            HStack {
                Text("Hired on")
                DateText(date: employee.hireDate)
            }
            .padding(5)

            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }

}


#Preview {
    EmployeeList()
}
