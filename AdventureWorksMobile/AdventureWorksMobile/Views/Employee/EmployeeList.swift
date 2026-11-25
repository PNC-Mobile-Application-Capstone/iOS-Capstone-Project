//
//  EmployeeList.swift
//  AdventureWorksMobile
//


import SwiftUI

struct EmployeeList: View {
    
    @State private var viewModel = ViewModel()
    @State private var isSearchVisible = false
    @Environment(\.employeeRepository) private var repository
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    private var searchButtonTitle: String {
        if isSearchVisible { return "Hide search" }
        if viewModel.searchText.isEmpty { return "Search" }
        return "Search: \(viewModel.searchText)"
    }
    
    var body: some View {
        let isLarge = dynamicTypeSize.isAccessibilitySize
        let controlRowLayout = isLarge
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .center))

        PageTemplate("Employees",
                     errorMessage: viewModel.errorMessage,
                     isLoading: viewModel.isLoading,
                     hasLoaded: viewModel.hasLoaded,
                     isEmpty: viewModel.isEmpty,
                     onRetry: { await viewModel.loadData(repository: repository, forceRefresh: true) },
                     dataStatus: viewModel.dataStatus,
                     onRefresh: { await viewModel.loadData(repository: repository, forceRefresh: true) }) {
            
            controlRowLayout {
                Button {
                    isSearchVisible.toggle()
                } label: {
                    Label(searchButtonTitle, systemImage: "magnifyingglass")
                }
                .accessibilityLabel(searchButtonTitle)
                .accessibilityIdentifier("employeeSearchButton")
                if !isLarge {
                    Spacer()
                }
                Button("Clear", action: viewModel.clearCriteria)
                    .disabled(!viewModel.hasActiveCriteria)
                    .accessibilityLabel("Clear search and sort")
                    .accessibilityIdentifier("clearCriteriaButton")
            }
            .padding(.vertical, 4)
            
            if isSearchVisible {
                TextField("Search name, department, or job title", text: $viewModel.searchText)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityLabel("Search employees by name, department, or job title")
                    .accessibilityIdentifier("employeeSearchField")
            }
            controlRowLayout {
                Text("Sort by")
                    .font(.subheadline)
                    .accessibilityHidden(true)
                if !isLarge {
                    Spacer()
                }
                Picker("Sort by", selection: $viewModel.sort) {
                    ForEach(EmployeeSort.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .accessibilityLabel("Sort by")
                .accessibilityValue(viewModel.sort.rawValue)
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
                    EmployeeListRow(employee: employee)
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

private struct EmployeeListRow: View {
    let employee: EmployeeRow
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let isLarge = dynamicTypeSize.isAccessibilitySize
        let topLayout = isLarge
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline))

        VStack(alignment: .leading, spacing: 4) {
            topLayout {
                Text(employee.displayName)
                if !isLarge {
                    Spacer()
                }
                if !employee.department.isEmpty {
                    Text(employee.department)
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
            }
            if !employee.jobTitle.isEmpty {
                Text(employee.jobTitle)
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(employee.accessibilitySummary)
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
    
    init(shift entry: ShiftEntry) {
        id = Int64(entry.employeeId)
        firstName = entry.firstName
        lastName = entry.lastName
        department = ""
        jobTitle = ""
        shift = entry.shift
        hireDate = nil
    }
    
    // First and last name, or a neutral placeholder when both are missing.
    var displayName: String {
        let name = [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
        return name.isEmpty ? "Name not listed" : name
    }

    var accessibilitySummary: String {
        let trimmedJob = jobTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDept = department.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = [displayName, trimmedJob, trimmedDept].filter { !$0.isEmpty }
        return parts.joined(separator: ", ") + "."
    }
}

extension EmployeeList {
    
    // @Observable redraws a view only when a property it reads changes.
    @MainActor
    @Observable
    class ViewModel {
        /// Every employee, revealed a page at a time as the user scrolls.
        var items = PagedItems<EmployeeRow>(pageSize: 25)
        private var allEmployees: [EmployeeRow] = []
        var dataStatus: DataStatus?
        var errorMessage: String = ""
        private(set) var isLoading = false
        private var loadWaiters: [CheckedContinuation<Void, Never>] = []
        private(set) var hasLoaded = false
        var isEmpty: Bool { allEmployees.isEmpty }
        
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
            if isLoading {
                guard !forceRefresh && !hasLoaded else { return }
                await withCheckedContinuation { loadWaiters.append($0) }
                if !Task.isCancelled && !hasLoaded && errorMessage.isEmpty {
                    await loadData(repository: repository)
                }
                return
            }
            guard forceRefresh || !hasLoaded, let repository else { return }
            isLoading = true
            errorMessage = ""
            defer {
                isLoading = false
                let waiters = loadWaiters
                loadWaiters.removeAll()
                waiters.forEach { $0.resume() }
            }

            do {
                let (employees, source) = try await repository.getAll(forceRefresh: forceRefresh)
                try Task.checkCancellation()
                dataStatus = DataStatus(source: source, lastUpdated: repository.lastUpdated)
                hasLoaded = true
                if source == .staleDisk {
                    errorMessage = "Couldn't refresh. Showing saved information."
                }
                // Copy out of Core Data, then sort and hand to PagedItems.
                setEmployees(employees.map(EmployeeRow.init))
                
                print("Loaded \(employees.count) items from \(source)")
            } catch {
                if !NetworkError.isCancellation(error) {
                    errorMessage = NetworkError.userMessage(for: error)
                }
            }
        }
        
    }
}

#Preview { EmployeeList() }
