//
//  EmployeeDetailView.swift
//  AdventureWorksMobile
//


import SwiftUI

/// One employee: a header with name and job title, a quick-look grid, then labeled rows.
/// Shows every field the employee repository returns:
/// id, firstName, lastName, jobTitle, department, shift, hireDate.
struct EmployeeDetails: View {

    @Environment(\.employeeRepository) private var repository
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var viewModel = ViewModel()
    
    var employee: EmployeeRow
    
    private var jobTitle: String {
        employee.jobTitle.isEmpty ? viewModel.jobTitle : employee.jobTitle
    }
    private var department: String {
        employee.department.isEmpty ? viewModel.department : employee.department
    }

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
                infoRow("Job Title", value: jobTitle.orPlaceholder)
                infoRow("Department", value: department.orPlaceholder)
                infoRow("Shift", value: employee.shiftName)
                LabeledContent("Hire Date") { DateText(date: employee.hireDate) }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Hire Date, \(DateText.spokenDate(employee.hireDate))")
                infoRow("Time at Company", value: employee.timeAtCompany)
            }
            
            Section("Employment History") {
                historyRows
            }

            Section("Personal") {
                infoRow("First Name", value: employee.firstName.orPlaceholder)
                infoRow("Last Name", value: employee.lastName.orPlaceholder)
                // Wrap in String so the ID shows without a comma.
                infoRow("Employee ID", value: String(employee.id))
            }
        }
        // Wrap in String so the ID shows without a comma.
        .navigationTitle(String("Employee #\(employee.id)"))
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await viewModel.loadHistory(for: employee.id, repository: repository) }
        .task { await viewModel.loadHistory(for: employee.id, repository: repository) }
    }

    // MARK: - Build components

    private func infoRow(_ label: String, value: String) -> some View {
        let spoken = (value == "--" || value == "—" || value.isEmpty) ? "Not listed" : value
        return LabeledContent(label, value: value)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(label), \(spoken)")
    }

    private var headerAccessibilityLabel: String {
        let title = jobTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? employee.displayName : "\(employee.displayName), \(title)"
    }

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

            Text(jobTitle.orPlaceholder)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        // VoiceOver reads the name and title as one item.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(headerAccessibilityLabel)
        .accessibilityAddTraits(.isHeader)
    }

    private var gridColumns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : 2
        return Array(repeating: GridItem(.flexible()), count: count)
    }

    private var overviewGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: 12) {
            StatBlock(label: "Department", value: department.orPlaceholder)
            StatBlock(label: "Shift", value: employee.shiftName)
            StatBlock(label: "Hired", value: DateText.displayDate(employee.hireDate))
            StatBlock(label: "Tenure", value: employee.timeAtCompany)
        }
    }
    
    @ViewBuilder
    private var historyRows: some View {
        if viewModel.isLoading && !viewModel.hasLoaded {
            HStack(spacing: 8) {
                ProgressView()
                Text("Loading history...")
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Loading employment history")
        }
        
        if !viewModel.errorMessage.isEmpty {
            Text("\(viewModel.errorMessage) Pull down to try again.")
                .font(.subheadline)
                .foregroundStyle(.red)
        }
        
        if viewModel.hasLoaded && viewModel.history.isEmpty {
            Text("No employment history on file.")
                .foregroundStyle(.secondary)
        }
        
        ForEach(viewModel.history) { entry in
            EmploymentHistoryRow(entry: entry)
        }
    }
}

// MARK: - ViewModel

extension EmployeeDetails {
    
    @MainActor
    @Observable
    class ViewModel {
        var history: [EmploymentHistoryEntry] = []
        var isLoading = false
        var hasLoaded = false
        var errorMessage = ""
        var jobTitle = ""
        var department = ""
        
        func loadHistory(for employeeId: Int64,
                         repository: (any TieredCacheRepositoryProtocol<Employee>)?) async {
            guard let repo = repository as? TieredCacheRepositoryBase<Employee> else { return }
            
            isLoading = true
            defer { isLoading = false }
            
            do {
                let detail = try await repo.loadDetail(for: employeeId)
                setHistory(detail.sortedHistory)
                jobTitle = detail.jobTitle ?? ""
                department = detail.sortedHistory.first(where: { $0.isCurrent })?.departmentName ?? ""
            }
            catch is CancellationError {  }
            catch let e as URLError where e.code == .cancelled {  }
            catch {
                errorMessage = error.localizedDescription
            }
        }
        
        func setHistory(_ entries: [EmploymentHistoryEntry]) {
            history = entries
            hasLoaded = true
            errorMessage = ""
        }
    }
}

private struct EmploymentHistoryRow: View {
    let entry: EmploymentHistoryEntry
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    var body: some View {
        let isLarge = dynamicTypeSize.isAccessibilitySize
        let topLayout = isLarge
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline))

        VStack(alignment: .leading, spacing: 2) {
            topLayout {
                Text(entry.departmentText)
                if !isLarge {
                    Spacer()
                }
                if entry.isCurrent {
                    Label {
                        Text("Current")
                    } icon: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    .font(.caption.weight(.semibold))
                }
            }
            Text(entry.groupAndShiftText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(entry.dateRangeText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(entry.accessibilitySummary)
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
