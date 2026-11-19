//
//  EmployeeList.swift
//  AdventureWorksMobile
//


import SwiftUI

struct EmployeeList: View {

    @State private var viewModel = ViewModel()
    @Environment(\.employeeRepository) private var repository

    var body: some View {
        PageTemplate("Employees",
                     errorMessage: viewModel.errorMessage,
                     isLoading: viewModel.isLoading,
                     hasLoaded: viewModel.hasLoaded,
                     isEmpty: viewModel.isEmpty,
                     onRetry: { await viewModel.loadData(repository: repository, forceRefresh: true) },
                     onRefresh: { await viewModel.loadData(repository: repository, forceRefresh: true) }) {
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
        // didSet re-sorts whenever the sort changes.
        var sort: EmployeeSort = .name { didSet { applySort() } }
        var source: CachedDataSource = .notcached
        var errorMessage: String = ""
        private(set) var isLoading = false
        private var loadWaiters: [CheckedContinuation<Void, Never>] = []
        private(set) var hasLoaded = false
        var isEmpty: Bool { allEmployees.isEmpty }


        private func applySort() {
            items.replace(with: allEmployees.sorted(using: sort.comparators))
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
                self.source = source
                hasLoaded = true
                if source == .staleDisk {
                    errorMessage = "Couldn't refresh. Showing saved information."
                }
                // Copy out of Core Data, then sort and hand to PagedItems.
                allEmployees = employees.map(EmployeeRow.init)
                
                applySort()
                
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
