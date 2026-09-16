# AdventureWorks Mobile — PNC Mobile Applications Bootcamp iOS Capstone

Enterprise Mobile Application Development Bootcamp, four-person Scrum team capstone. Native iOS client for the AdventureWorks operations API, built with Swift and SwiftUI.

## Mission

Give AdventureWorks employees and managers timely access to operational information while away from their desks: sign in, review a live operations dashboard, browse employees and products, track inventory, and inspect orders — all backed by live data from the AdventureWorks API rather than hard-coded content.

## Team

| Focus role                   | Responsibility                                                        | Owner (rotates at least once) |
| ---------------------------- | --------------------------------------------------------------------- | ----------------------------- |
| Scrum Facilitator            | Planning, stand-ups, backlog refinement, review, retrospective        | TBD                           |
| Technical Lead               | Architecture, integration choices, PR quality, technical risk         | TBD                           |
| Quality & Accessibility Lead | Test strategy, acceptance checks, accessibility review, defect triage | TBD                           |
| Product & UX Liaison         | Business value, priorities, flow coordination, stakeholder feedback   | TBD                           |

All members are developers and contribute code; no one is the sole owner of an application area.

## Tech Stack

- Swift, SwiftUI (primary UI)
- Swift concurrency (async/await) for networking
- MVVM with a reusable API client in a services/repository layer
- Codable models for API responses
- XCTest (unit tests + at least one UI test of a critical path)
- Swift Package Manager for approved third-party dependencies
- Git / GitHub, feature branches, protected `main`, reviewed pull requests

## API

- Base URL: `https://api.bootcampcentral.com/`
- Swagger / API docs: `https://api.bootcampcentral.com/swagger/index.html`
- Test credentials: see the team's private credentials doc — **do not commit usernames, passwords, or tokens to this repository.** Store session tokens using an appropriate secure mechanism (e.g., Keychain), never in source or logs.

## Scope

**Required (MVP baseline):** secure sign-in and session management; operational dashboard; employee directory and profile; search/sort/filter; product catalog and details; inventory awareness; order exploration; refresh and current-state feedback (loading/empty/error states); failure recovery and partial availability; accessible and adaptable interface (Dynamic Type, VoiceOver).

**Choice (team selects at least two):** authorized inventory adjustment; employee information update; token renewal; local continuity (limited offline value).

Full requirement text: `iOSCapstoneRequirements.pdf` in this folder.

## Architecture

- **Views** — SwiftUI, presentation only
- **ViewModels** — presentation/state logic, `@MainActor` where appropriate
- **Services / Repositories** — reusable API client, request/response mapping, error mapping
- **Models** — typed `Codable` structs for API payloads

_(Expand this section with the team's actual module layout and any deviations from MVVM once agreed.)_

## Getting Started

_(Fill in once the Xcode project exists.)_

1. Clone the repository: `git clone <repo-url>`
2. Open `<ProjectName>.xcodeproj` / `.xcworkspace` in Xcode `<version>`
3. Resolve Swift Package dependencies (automatic on open)
4. Add API test credentials per the team's setup doc (not committed)
5. Build and run on iOS `<minimum supported version>`

## Testing

- Unit tests: business/presentation logic and networking, using mocks/stubs/injected test doubles
- UI tests: at least one critical-path flow
- Run tests: `Cmd+U` in Xcode, or `xcodebuild test -scheme <scheme>`

See the test report (added under `Documentation/`) for coverage priorities and known unresolved defects.

## Known Limitations

_(Update as the project develops — call out anything intentionally out of scope or deferred past the MVP.)_

## Project Planning

- Team checklist and phased approach: see the group's shared Claude Doc (linked in the team channel)
- Backlog, sprint board, and Scrum artifacts: see the team's board tool export under `Documentation/`

## Contributing

- Branch from `main` using short-lived feature branches
- Open a pull request for review before merging; no direct pushes to `main`
- Keep commits small and meaningful
- Follow the team's agreed Definition of Ready / Definition of Done
