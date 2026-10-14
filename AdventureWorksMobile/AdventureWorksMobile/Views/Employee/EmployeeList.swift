//
//  EmployeeList.swift
//  AdventureWorksMobile
//
//  Created by Tyler Swindell on 10/14/26.
//


import SwiftUI

struct EmployeeList: View {

    @State private var viewModel = ViewModel()
    @Environment(\.employeeRepository) private var repository

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ListHeader(title: "Employees",
                           source: viewModel.source,
                           errorMessage: viewModel.errorMessage)

                List {
                    ForEach(viewModel.items.shown) { employee in
                        NavigationLink {
                            EmployeeDetails(employee: employee)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text("\(employee.firstName ?? "Missing First Name") \(employee.lastName ?? "Missing Last Name")")
                                    Spacer()
                                    Text("\(employee.department ?? "Missing Department")")
                                        .foregroundStyle(.secondary)
                                        .font(.subheadline)
                                }
                                Spacer()
                                Text(employee.jobTitle ?? "Missing Job Title")
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
            }
            .background(Color(.systemGroupedBackground))
            // Title is drawn by ListHeader so it stays put while the list
            // scrolls. navigationTitle still labels the back button.
            .navigationTitle("Employees")
            .toolbar(.hidden, for: .navigationBar)
            .task { await viewModel.loadData(repository: repository) }
        }
    }
}

enum EmployeeSort: String, CaseIterable, Identifiable {
    case name = "Name"
    case department = "Department"
    var id: Self { self }

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
}

extension EmployeeList {

    @Observable
    class ViewModel {
        /// Every employee, revealed a page at a time as the user scrolls.
        var items = PagedItems<EmployeeRow>(pageSize: 25)
        private var allEmployees: [EmployeeRow] = []
        var sort: EmployeeSort = .name { didSet { applySort() } }
        var source: CachedDataSource = .notcached
        var errorMessage: String = ""


        private func applySort() {
            items.replace(with: allEmployees.sorted(using: sort.comparators))
        }
        
        func loadData(repository: (any TieredCacheRepositoryProtocol<Employee>)?) async {
            guard let repository = repository else { return }

            do {
                let (employees, source) = try await repository.getAll()
                self.source = source
                allEmployees = employees.map(EmployeeRow.init)   // copy out of Core Data
                
                applySort()                                      // sort, then hand to PagedItems
                
                print("Loaded \(employees.count) items from \(source)")
            } catch {
                errorMessage = error.localizedDescription
            }
        }

    }
}

#Preview { EmployeeList() }
