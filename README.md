# AdventureWorks Mobile: PNC Mobile Applications Bootcamp iOS Capstone

Enterprise Mobile Application Development Bootcamp, four-person Scrum team capstone. Native iOS client for the AdventureWorks operations API, built with Swift and SwiftUI.

## Mission

Give AdventureWorks employees and managers timely access to operational information while away from their desks: sign in, review a live operations dashboard, browse employees and products, track inventory, and inspect orders. All backed by live data from the AdventureWorks API rather than hard-coded content.

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
- Test credentials: see the team's private credentials doc, **do not commit usernames, passwords, or tokens to this repository.** Store session tokens using an appropriate secure mechanism (e.g., Keychain), never in source or logs.

## Scope

**Required (MVP baseline):** secure sign-in and session management; operational dashboard; employee directory and profile; search/sort/filter; product catalog and details; inventory awareness; order exploration; refresh and current-state feedback (loading/empty/error states); failure recovery and partial availability; accessible and adaptable interface (Dynamic Type, VoiceOver).

**Choice (team selects at least two):** authorized inventory adjustment; employee information update; token renewal; local continuity (limited offline value).

Full requirement text: `iOSCapstoneRequirements.pdf` in this folder.

## Architecture

- **Views**: SwiftUI, presentation only
- **ViewModels**: presentation/state logic, `@MainActor` where appropriate
- **Services / Repositories**: reusable API client, request/response mapping, error mapping
- **Models**: typed `Codable` structs for API payloads

The current implementation is organized into:

- Views: login and product-list presentation
- Models: authentication request/response state
- Services: login, refresh-token, JSON decoding, and Keychain access
- Repositories: authenticated API access and tiered product caching
- Data: Core Data stack and managed product model
- App: dependency-injection keys and shared error types

Authentication tokens are stored in Keychain. Product reads use a 15-minute
memory/Core Data cache, refresh stale data from the API, and fall back to stale
disk data when the network is unavailable.

## Getting Started

1. Clone the repository.
2. Open `AdventureWorksMobile/AdventureWorksMobile.xcodeproj` in a version of
   Xcode that supports the deployment target configured in the project.
3. Resolve Swift Package dependencies (automatic on open)
4. Build and run the `AdventureWorksMobile` scheme.
5. Enter the team-provided API test credentials on the login screen. Credentials
   and tokens must not be committed.

## Testing

- Unit tests: business/presentation logic and networking, using mocks/stubs/injected test doubles
- UI tests: at least one critical-path flow
- Run tests with `Cmd+U` in Xcode.
- Command line: `xcodebuild test -project AdventureWorksMobile/AdventureWorksMobile.xcodeproj -scheme AdventureWorksMobile -destination 'platform=iOS Simulator,name=<simulator name>'`

## Known Limitations

- Product listing and authenticated session management are implemented.
- Product details, employee, inventory, order, and dashboard features remain to
  be implemented.
- Stale product data is intentionally displayed when an API refresh fails.

## Project Planning

- Team checklist and phased approach: see the group's shared Claude Doc (linked in the team channel)
- Backlog, sprint board, and Scrum artifacts are maintained in the team's board tool.

## Contributing

- Branch from `main` using short-lived feature branches
- Open a pull request for review before merging; no direct pushes to `main`
- Keep commits small and meaningful
- Follow the team's agreed Definition of Ready / Definition of Done
