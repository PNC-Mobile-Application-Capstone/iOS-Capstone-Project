//
//  EmployeeDetailView.swift
//  AdventureWorksMobile
//


import SwiftUI

struct EmployeeDetails: View {
    
    @Environment(\.employeeRepository) private var repository

    var employee: EmployeeRow
    

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
            
            Text("Employee ID: \(employee.id)")
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
