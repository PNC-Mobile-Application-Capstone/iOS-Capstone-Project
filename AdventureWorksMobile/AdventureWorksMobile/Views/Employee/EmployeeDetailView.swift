//
//  EmployeeDetailView.swift
//  AdventureWorksMobile
//


import SwiftUI

/// One employee: a header with name and job title, a quick-look grid, then labeled rows.
/// Shows every field the employee repository returns:
/// id, firstName, lastName, jobTitle, department, shift, hireDate.
struct EmployeeDetails: View {

    // Not used yet. Kept for a later call to GET /api/Employee/{id} (employment history).
    @Environment(\.employeeRepository) private var repository

    var employee: EmployeeRow

    var body: some View {
        List {
            Section {
                header
                    .listRowBackground(Color.clear)
            }

            Section("Overview") {
                overviewGrid
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
            }

            Section("Employment") {
                LabeledContent("Job Title", value: employee.jobTitle.orPlaceholder)
                LabeledContent("Department", value: employee.department.orPlaceholder)
                LabeledContent("Shift", value: employee.shiftName)
                LabeledContent("Hire Date") { DateText(date: employee.hireDate) }
                LabeledContent("Time at Company", value: employee.timeAtCompany)
            }

            Section("Personal") {
                LabeledContent("First Name", value: employee.firstName.orPlaceholder)
                LabeledContent("Last Name", value: employee.lastName.orPlaceholder)
                // Wrap in String so the ID shows without a comma.
                LabeledContent("Employee ID", value: String(employee.id))
            }
        }
        // Wrap in String so the ID shows without a comma.
        .navigationTitle(String("Employee #\(employee.id)"))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Build components

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(height: 96)
                .foregroundStyle(.secondary)
                // Decorative. The name below says who this is.
                .accessibilityHidden(true)

            Text(employee.displayName)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            Text(employee.jobTitle.orPlaceholder)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        // VoiceOver reads the name and title as one item.
        .accessibilityElement(children: .combine)
    }

    private var overviewGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatBlock(label: "Department", value: employee.department.orPlaceholder)
            StatBlock(label: "Shift", value: employee.shiftName)
            StatBlock(label: "Hired", value: DateText.displayDate(employee.hireDate))
            StatBlock(label: "Tenure", value: employee.timeAtCompany)
        }
    }
}

// MARK: - Display helpers

extension EmployeeRow {

    /// Shift name, or "--" when the API sends none.
    var shiftName: String {
        (shift ?? "").orPlaceholder
    }

    /// Whole years since the hire date, for example "12 years" or "Less than 1 year".
    /// "--" when the hire date is missing or can't be read.
    var timeAtCompany: String {
        guard let hired = DateText.parseDate(hireDate) else { return "--" }
        let years = Calendar.current.dateComponents([.year], from: hired, to: .now).year ?? 0
        switch years {
        case ..<1: return "Less than 1 year"
        case 1:    return "1 year"
        default:   return "\(years) years"
        }
    }
}

private extension String {
    /// Trimmed text, or "--" when blank. Matches DateText's placeholder.
    var orPlaceholder: String {
        let text = trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? "--" : text
    }
}

#Preview {
    EmployeeList()
}
