# AdventureWorks Mobile: PNC Mobile Applications Bootcamp iOS Capstone

Enterprise Mobile Application Development Bootcamp, four-person Scrum team capstone. Native iOS client for the AdventureWorks operations API, built with Swift and SwiftUI.

## Contents

1. [Mission](#mission)
2. [Team](#team)
3. [Supported Versions](#supported-versions)
4. [Setup](#setup)
5. [Configuration](#configuration)
6. [Credentials Procedure](#credentials-procedure)
7. [Architecture Summary](#architecture-summary)
8. [Testing](#testing)
9. [Known Limitations](#known-limitations)
10. [Project Planning and Scrum Artifacts](#project-planning-and-scrum-artifacts)
11. [Contributing](#contributing)

## Mission

Give AdventureWorks employees and managers quick access to store data while away from their desks. They sign in, check a live dashboard, browse employees and products, track inventory, and look up orders. Every screen uses live data from the AdventureWorks API, not hard-coded content.

**Required (all built or in progress):** secure sign-in and session; operational dashboard; employee directory and profile; search, sort, and filter; product catalog and details; inventory awareness; order exploration; refresh and current-state feedback; failure recovery and partial availability; accessible and adaptable interface.

**Choice features picked:** Token Renewal (13) and Local Continuity (14).

**Order audience:** customer orders (`GET /api/Order/customer`), not store orders.

Full requirement text: `iOSCapstoneRequirements.pdf`.

## Team

All members are developers and write code. No one is the only owner of an app area. Every pull request is reviewed by a teammate.

| Focus role                   | Responsibility                                                        | Sprints 1 and 2 (09/18 to 10/15) | From 10/16 (after rotation) |
| ---------------------------- | --------------------------------------------------------------------- | -------------------------------- | --------------------------- |
| Scrum Facilitator            | Planning, stand-ups, backlog refinement, review, retrospective        | Tyler Swindell                   | Tyler Swindell              |
| Technical Lead               | Architecture, integration choices, PR quality, technical risk         | Nathan Bergman                   | Nathan Bergman              |
| Quality & Accessibility Lead | Test strategy, acceptance checks, accessibility review, defect triage | Aza Mohanty                      | Jonah Kriess                |
| Product & UX Liaison         | Business value, priorities, flow coordination, stakeholder feedback   | Jonah Kriess                     | Aza Mohanty                 |

**Role rotation.** The requirements say roles must rotate at least once. Ours rotated on 10/16, when the team started the Android capstone. Jonah and Aza swapped the Quality & Accessibility and Product & UX roles. Full details: [`Documentation/Role-Rotation.md`](Documentation/Role-Rotation.md).

## Supported Versions

| Item | Value |
| --- | --- |
| Xcode | 26.6 or newer (project created in Xcode 26.6, last upgrade check in Xcode 27) |
| iOS deployment target | iOS 26.5. Older iOS versions cannot install the app |
| Swift | Swift 5 language mode, default actor isolation `MainActor` |
| Third-party packages | None. Apple frameworks only (SwiftUI, Core Data, Security, CryptoKit). The weekly sales bar chart is a custom SwiftUI view |
| Device family | iPhone (primary). The target also allows iPad, but the layouts were not designed or tested for iPad |
| Orientation | Portrait is the supported layout. The project setting still allows landscape on iPhone, but landscape was not tested |
| Simulators tested | [Fill in: smallest and largest iPhone used, for example iPhone SE (3rd generation) and iPhone 17 Pro Max] |
| Bundle ID | `com.pncbootcamp.AdventureWorksMobile` |

## Setup

**Before you start**
- A Mac with Xcode 26.6 or newer.
- An iPhone simulator runtime for iOS 26.5 or newer. Add one in Xcode under Settings, Components.
- Access to the team GitHub repository.
- A set of API test credentials. See [Credentials Procedure](#credentials-procedure).

**Steps**
1. Clone the repository and switch to the branch you want to run. `dev` is the newest tested code. `main` is the release branch.
   ```bash
   git clone <repository URL>
   cd <repository folder>
   git checkout dev
   ```
2. Open `AdventureWorksMobile/AdventureWorksMobile.xcodeproj` in Xcode.
3. Wait for Xcode to finish indexing. There are no packages to fetch.
4. Pick the `AdventureWorksMobile` scheme and an iPhone simulator.
5. Press `Cmd+R` to build and run.
6. Sign in with your API test credentials.

**To run on a real iPhone:** select the `AdventureWorksMobile` target, open Signing & Capabilities, and pick your own Team. If the bundle ID is taken on your account, change it to something unique. Do not commit that change.

## Configuration

The app has one environment. All settings live in source code. There are no `.xcconfig`, `.plist`, or secrets files to create.

| Setting | Value | Where to change it |
| --- | --- | --- |
| API base URL | `https://api.bootcampcentral.com/api` | `App/APIEndpoint.swift`, `APIEndpoint.baseURL` |
| API routes | One `case` per route, paths match Swagger | `App/APIEndpoint.swift`, `path` |
| Cache lifetime | 15 minutes for memory and Core Data | `Repositories/TieredCacheRepositoryBase.swift`, `maxAge` |
| Keychain service name | `com.adventure-works-mobile-app.auth` | `Services/SecureTokenManager.swift`, `service` |
| Keychain token keys | `userAccessToken`, `userRefreshToken` | `Models/AuthStatus.swift` |
| Stock status rules | Out of stock at 0 or less. Critical at 25% of safety stock or less. Reorder at or below the reorder point. Low below safety stock | `Models/Inventory/StockLevel.swift` |
| Dashboard data source | `CoreDataDashboardRepository` in the app. `MockDashboardRepository` for previews | `AdventureWorksMobileApp.swift` |

Swagger docs for the API: `https://api.bootcampcentral.com/swagger/index.html`

**Swapping a data source.** `AdventureWorksMobileApp` builds each repository once and passes it down with `.environment(...)`. To use a fake, pass a different object to the matching environment key in `App/RepositoryInjectionKeys.swift`. No view code changes.

## Credentials Procedure

The app signs in against the real AdventureWorks API. Each tester needs a username (`loginId`) and password.

**Getting credentials**
1. The instructor gives the team its API test accounts.
2. The Scrum Facilitator stores them in the team's private credentials doc. That doc is shared only with the four team members.
3. Ask the Scrum Facilitator for access if you do not have it.

**Using credentials**
1. Run the app. The sign-in screen opens first.
2. Enter the username and password from the private doc. Both fields are required.
3. The app sends them once to `POST /api/Login`. It does not save the password anywhere.
4. The API returns an access token and a refresh token. Both are saved in the iOS Keychain. They use the "after first unlock, this device only" setting, so they do not sync to iCloud or move to a backup on another phone.
5. Every API call adds `Authorization: Bearer <access token>`.
6. When a call returns 401, the app calls `POST /api/Login/refresh` once and retries once. If that fails, it clears both tokens and returns to sign-in.

**Signing out or resetting**
- Open Account (top right) and tap Sign Out. This deletes both tokens from the Keychain.
- On the simulator, you can also use Device, Erase All Content and Settings.

**Rules**
- Never commit usernames, passwords, or tokens. That includes code, comments, test files, screenshots, and commit messages.
- Never print a token or password to the console.
- Unit tests use fake values (for example `employee` / `secret`) against a stubbed network. They never reach the real API.
- If a real credential is pushed by mistake, tell the Scrum Facilitator and the instructor right away so the account can be reset. Removing it in a later commit is not enough, because it stays in Git history.

## Architecture Summary

The app uses MVVM with a repository layer. Views show data. ViewModels hold screen state. Repositories get the data, from cache or from the API.

### How a request gets to the screen

```
SwiftUI View
   |  asks
   v
ViewModel (@Observable, holds loading / items / errorMessage)
   |  asks
   v
TieredCacheRepositoryBase<Item>     1. memory (NSCache, 15 min)
   |                                2. Core Data (15 min)
   |                                3. API, then save to Core Data
   v
RemoteRepositoryBase<Item>          adds "Bearer <token>" from Keychain
   |                                on a 401: refresh once, retry once, else sign out
   v
URLSession  -->  AdventureWorks API
```

If the API call fails and old rows are saved on disk, the repository returns them marked as `staleDisk`. The screen keeps showing data instead of going blank. This is our Local Continuity feature.

### Tech stack

- Swift, SwiftUI, Swift concurrency (async/await)
- Core Data for the offline cache, Keychain for tokens
- `Codable` models decode the API JSON straight into Core Data objects
- Swift Testing for unit tests, XCTest for UI tests
- Git and GitHub: feature branches, `dev` for staging, protected `main`, reviewed pull requests

### Folder layout (`AdventureWorksMobile/AdventureWorksMobile/`)

| Folder | What lives there |
| --- | --- |
| `App/` | `APIEndpoint` (every API path in one enum), `NetworkError` (plain error messages), environment keys for injecting repositories |
| `Services/` | `AuthService` (login and token refresh calls), `SecureTokenManager` (Keychain), shared JSON decoder |
| `Models/` | `AuthStatus` (signed-in state), login models, dashboard entries, employee detail, inventory stock levels |
| `Repositories/` | `RemoteRepositoryBase` (the one API client), `TieredCacheRepositoryBase` (memory, disk, API), detail and photo extensions, dashboard repositories (remote, Core Data, mock) |
| `Data/` | Core Data stack (`PersistenceController`) and managed classes for Product, Employee, Inventory, CustomerOrder, and the dashboard tables |
| `Cache/` | `CacheBox`, the wrapper stored in the memory cache |
| `Views/` | One folder per feature (Product, Employee, Inventory, CustomerOrder), plus `DashboardView`, `LoginView`, `AccountView`, and `Shared/` building blocks (`PageTemplate`, `PagedItems`, `ListHeader`, `StockStatusIcon`, and more) |

### Key design choices

- **One API client.** Every network call goes through `RemoteRepositoryBase`. It adds the token, checks the status code, and maps errors to `NetworkError`.
- **One generic cache.** `TieredCacheRepositoryBase<Item>` serves Products, Employees, Inventory, and Customer Orders. Detail screens and product photos use extensions on the same class.
- **Injection through the environment.** Tests and previews pass in fakes or the mock dashboard repository.
- **Dashboard loads in parts.** Each of the four dashboard calls runs on its own. One failure does not hide the other sections. The last good dashboard is saved in Core Data and shows on launch while the API updates.
- **Navigation.** A `TabView` with five tabs: Dashboard, Products, Inventory, Orders, Employees. Account opens as a sheet from the top right, so iPhone never moves tabs under "More."
- **Security.** Access and refresh tokens live in Keychain only. No screen is reachable before sign-in. Sign out clears both tokens.

## Testing

- **Unit tests** (`AdventureWorksMobileTests`, Swift Testing): 23 tests. They cover login and token storage, token refresh and retry, sign-out on a failed refresh, product and inventory decoding, the three cache tiers, product, order, and inventory search and sort, stock levels, and dashboard section errors. Network calls use a `URLProtocol` stub, and tokens use an in-memory store.
- **UI tests** (`AdventureWorksMobileUITests`, XCTest): login needs both fields, and no tab is visible before sign-in. Plus the default launch tests.
- Run tests with `Cmd+U` in Xcode.
- Command line:
  ```bash
  xcodebuild test \
    -project AdventureWorksMobile/AdventureWorksMobile.xcodeproj \
    -scheme AdventureWorksMobile \
    -destination 'platform=iOS Simulator,name=<simulator name>'
  ```

## Known Limitations

Status as of 11/25/26, `dev` at `34cf0d4`.

**Setup and configuration**
- There is one hard-coded environment. Pointing the app at a different API means editing `APIEndpoint.baseURL` and rebuilding.
- Some `print()` calls still run in release builds. They log failed dashboard and lookup calls and a product photo hash. They do not log tokens or passwords.

**Refresh, errors, and recovery (Req 8 and 9)**
- There is no Retry button. Users recover by pulling down to refresh.
- List screens have no first-load spinner. A slow first call shows an empty list.
- List screens have no empty state outside of search ("No results").
- Nothing stops a second load while one is running. The first `.task` load and pull-to-refresh can overlap.
- List screens show the system error text (`localizedDescription`) for errors that are not a `NetworkError`.

**Dashboard (Req 2)**
- Top Sellers and Underperforming show one product each, not a list.
- A failed section shows one shared message ("Some dashboard data couldn't be updated. Pull down to try again."), not a message inside that section.
- Weekly sales uses whatever range the API returns. The Product Owner never confirmed calendar week or rolling 7 days.

**Local Continuity (Choice 14)**
- The app tracks whether data came from the cache or the API. A "Last updated" / "Offline, showing saved data" line is in progress and not merged to `dev`.
- Cached data is replaced only on a full refresh. Rows deleted on the server stay on the phone until the next good refresh.

**Products (Req 5)**
- Product Line code `S` shows as "S." Only R, M, and T map to a full name.

**Employees (Req 3)**
- The employee repository has no unit tests.

**Accessibility (Req 10)**
- VoiceOver labels exist on Inventory rows, the Employee header, the dashboard chart, and the scroll-to-top button. Product, Order, and Employee list rows use the default reading.
- The largest Dynamic Type size was checked on Inventory only.

**Roles and permissions**
- The API has no manager or role flag, so every signed-in user sees the same five tabs. We chose not to guess a role from free-text job titles.
- The app is read-only. Inventory adjustment (11) and Employee Info Update (12) were not built. Their routes exist in `APIEndpoint`, but no screen calls them.

**Devices**
- iPad and landscape are allowed by the project settings but were not tested.

**Testing**
- No UI test covers the full critical path (sign in, open Products, open a detail).

## Project Planning and Scrum Artifacts

All in [`Documentation/`](Documentation/):

| File | What it holds |
| --- | --- |
| `User-Stories.md` | User stories and acceptance criteria for every requirement |
| `Role-Rotation.md` | Who held each role, when it changed, and why |
| `Retrospective.md` | Final retro: what went well, what was hard, what we would change |
| `Board-Screenshots/` | One task board screenshot per sprint |
| `Contribution-Summaries.md` | One summary per team member |

## Contributing

- Branch from `dev` using short-lived feature branches.
- Open a pull request for review. No direct pushes to `main`.
- `dev` is merged into `main` after testing.
- Keep commits small and meaningful.
- Check every pull request for credentials, tokens, and personal paths before you ask for review.
- Follow the team's Definition of Ready and Definition of Done.
