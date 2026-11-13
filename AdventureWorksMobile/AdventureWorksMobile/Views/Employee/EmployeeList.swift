//
//  EmployeeList.swift
//  AdventureWorksMobile
//


import SwiftUI

struct EmployeeList: View {
    
    @State private var viewModel = ViewModel()
    @State private var isSearchVisible = false
    @Environment(\.employeeRepository) private var repository
    
    private var searchButtonTitle: String {
        if isSearchVisible { return "Hide search" }
        if viewModel.searchText.isEmpty { return "Search" }
        return "Search: \(viewModel.searchText)"
    }
    
    var body: some View {
        PageTemplate("Employees",
                     errorMessage: viewModel.errorMessage,
                     onRefresh: { await viewModel.loadData(repository: repository, forceRefresh: true) }) {
            
            HStack {
                Button {
                    isSearchVisible.toggle()
                } label: {
                    Label(searchButtonTitle, systemImage: "magnifyingglass")
                }
                .accessibilityIdentifier("employeeSearchButton")
                Spacer()
                Button("Clear", action: viewModel.clearCriteria)
                    .disabled(!viewModel.hasActiveCriteria)
                    .accessibilityIdentifier("clearCriteriaButton")
            }
            .padding(.vertical, 4)
            
            if isSearchVisible {
                TextField("Search name, department, or job title", text: $viewModel.searchText)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("employeeSearchField")
            }
            HStack {
                Text("Sort by")
                    .font(.subheadline)
                Spacer()
                Picker("Sort by", selection: $viewModel.sort) {
                    ForEach(EmployeeSort.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .accessibilityIdentifier("employeeSortPicker")
            }
            
        } content: {
            if viewModel.isSearching, viewModel.items.all.isEmpty {
                ContentUnavailableView.search(text: viewModel.searchText)
                    .listRowBackground(Color.clear)
            }
            
            ForEach(viewModel.items.shown) { employee in
                NavigationLink {
                    EmployeeDetails(employee: employee)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(employee.displayName)
                            Spacer()
                            Text(employee.department)
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }
                        Spacer()
                        Text(employee.jobTitle)
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                }
            }
            
            // Reached the last loaded employee: show the next page.
            if viewModel.items.hasMore {
                LoadMoreRow { viewModel.items.loadMore() }
            }
        }
        // Load the data when the screen appears.
        .task { await viewModel.loadData(repository: repository) }
    }
}

enum EmployeeSort: String, CaseIterable, Identifiable {
    case name = "Name"
    case department = "Department"
    var id: Self { self }
    
    // Sort keys in order. A tie on one key falls to the next.
    var comparators: [KeyPathComparator<EmployeeRow>] {
        switch self {
        case .name:       [.init(\.lastName), .init(\.firstName)]
        case .department: [.init(\.department), .init(\.lastName), .init(\.firstName)]
        }
    }
}

/// Plain copy of one Employee. Safe to hold after the cache refreshes.
struct EmployeeRow: Identifiable, Hashable {
    let id: Int64
    let firstName: String
    let lastName: String
    let department: String
    let jobTitle: String
    let shift: String?
    let hireDate: String?
    
    init(_ e: Employee) {
        id = e.id
        firstName = e.firstName ?? ""
        lastName = e.lastName ?? ""
        department = e.department ?? ""
        jobTitle = e.jobTitle ?? ""
        shift = e.shift
        hireDate = e.hireDate
    }
    
    // First and last name, or a neutral placeholder when both are missing.
    var displayName: String {
        let name = [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
        return name.isEmpty ? "Name not listed" : name
    }
}

extension EmployeeList {
    
    // @Observable redraws a view only when a property it reads changes.
    @Observable
    class ViewModel {
        /// Every employee, revealed a page at a time as the user scrolls.
        var items = PagedItems<EmployeeRow>(pageSize: 25)
        private var allEmployees: [EmployeeRow] = []
        var source: CachedDataSource = .notcached
        var errorMessage: String = ""
        
        // didSet re-sorts whenever the sort changes.
        var searchText = "" {
            didSet {
                applyCriteria(resetPage: true)
            }
        }
        var sort: EmployeeSort = .name {
            didSet {
                applyCriteria(resetPage: true)
            }
        }
        
        var hasActiveCriteria: Bool {
            !searchText.isEmpty || sort != .name
        }
        
        var isSearching: Bool {
            !trimmedSearchText.isEmpty
        }
        
        private var trimmedSearchText: String {
            searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        func clearCriteria() {
            searchText = ""
            sort = .name
        }
        
        func setEmployees(_ values: [EmployeeRow]) {
            allEmployees = values
            applyCriteria(resetPage: false)
        }
        
        
        private func applyCriteria(resetPage: Bool) {
            let query = trimmedSearchText
            let matches = allEmployees.filter { employee in
                query.isEmpty || employee.displayName.localizedStandardContains(query)
                || employee.department.localizedStandardContains(query)
                || employee.jobTitle.localizedStandardContains(query)
            }
            items.replace(with: matches.sorted(using: sort.comparators), resetPage: resetPage)
        }
        
        func loadData(repository: (any TieredCacheRepositoryProtocol<Employee>)?, forceRefresh: Bool=false) async {
            guard let repository = repository else { return }
            
            do {
                let (employees, source) = try await repository.getAll(forceRefresh: forceRefresh)
                self.source = source
                errorMessage = ""
                // Copy out of Core Data, then sort and hand to PagedItems.
                setEmployees(employees.map(EmployeeRow.init))
                
                print("Loaded \(employees.count) items from \(source)")
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        
    }
}

#Preview { EmployeeList() }
