# Individual Contribution Summaries

**Requirement:** Each member writes an individual contribution summary (`iOSCapstoneRequirements.pdf`). The instructor may compare it to the repo history, so every claim below points to commits or PRs.

> **Draft.** Each summary was drafted from the Git history of both repos (all branches, as of 11/18/26). Each member must read their own section, fix anything wrong, and fill in the [brackets] in their own words before the presentation.

## Commit and PR Snapshot

Unique non-merge commits across all branches. "PRs merged" counts the PRs each person merged on GitHub, which is where reviews were approved.

| Member | iOS commits | iOS PRs merged | Android commits | Android PRs merged |
| --- | --- | --- | --- | --- |
| Tyler Swindell | 37 | 5 | 18 | 2 |
| Nathan Bergman | 7 | 6 | 8 | 3 |
| Jonah Kriess | 12 | 3 | 6 | 2 |
| Aza Mohanty | 4 | 4 | 12 | 9 |

Commit counts do not measure effort. Some members made large commits. Others made many small ones.

---

## Tyler Swindell

**Roles:** Scrum Facilitator for the whole project.

**What I built (iOS)**
- Repository layer: `RemoteRepositoryBase`, the one API client that adds the token to every call and maps errors (09/27).
- Login session: `AuthStatus` and `SecureTokenManager`. Both tokens in Keychain. Sign out clears them (09/27 to 10/03).
- Token renewal (Choice 13): refresh once on a 401, retry once, sign out on failure. Unit tested.
- `TieredCacheRepositoryBase`: one generic memory, Core Data, and API cache. Folded four separate cache classes into it, and added the product photo loader as an extension (10/10). This is our Local Continuity feature (Choice 14).
- Core Data models and repositories for Employee, Inventory, and Customer Order (10/07 to 10/09).
- Product details, customer order list and detail, employee list and detail, and lazy paging (`PagedItems`) (10/01 to 10/14).
- `PageTemplate`, the shared screen layout with tap-to-top headers and a scroll-to-top button (10/22).
- Inventory awareness screen with icon plus text stock levels, and the dashboard low-stock icons (10/27 to 11/05).

**What I built (Android)**
- Recently Viewed: screen, offline support, Clear history, and in-memory Room tests (10/29 to 11/16).
- Shared `AppError` type and friendly error messages on every screen (11/11).
- OkHttp timeouts so no call waits forever (11/16).

**Scrum work**
- Ran planning and team meetings. Wrote the agendas, notes, `BACKLOG.md`, Definition of Done draft, and status reviews.
- Wrote the README, user stories, role rotation, and retro docs.

**What I learned:** [One or two sentences in your own words.]

---

## Nathan Bergman

**Roles:** Technical Lead for the whole project.

**What I built (iOS)**
- Base app setup and first navigation (PR #1, 09/21).
- Build fixes, README and `.gitignore` cleanup (09/29).
- Login screen updates (10/13).
- Search and sort for Products and Orders (Req 4), and the shared list header used for search controls (10/18).

**What I built (Android)**
- Project skeleton: Gradle setup, Hilt, Retrofit, Room, and package layers (10/18 to 10/20).
- Product catalog and app UI (10/21).
- Saved products with offline persistence (10/22 to 11/05).
- Home sections inside the Catalog tab: recently viewed and recent orders, each with its own Retry (11/16).

**Tech Lead work**
- Set architecture rules for both apps. Merged and reviewed the most iOS PRs (6).

**What I learned:** [One or two sentences in your own words.]

---

## Jonah Kriess

**Roles:** Product & UX Liaison (to 10/15), then Quality & Accessibility Lead (from 10/16).

**What I built (iOS)**
- Dashboard: first layout with a mock repository behind a protocol (10/02), then live data from all four endpoints (10/14).
- Bottom tab bar and the Account screen (10/10).
- Pull to refresh that skips the cache (10/19).
- Rebuilt product details with full Core Data caching (10/21).
- Weekly sales bar chart (10/22) with VoiceOver labels (11/12).
- Dashboard error messages with unit tests (11/12).
- Employee search and sort, and employment history on the profile (11/13).
- Dashboard saved in Core Data and shown on launch (11/15). Interactive shift picker and tap-to-detail links (11/16).

**What I built (Android)**
- Unit tests for product and order DTOs, repositories, the recently viewed entity, and ViewModels (11/05 to 11/07).

**What I learned:** [One or two sentences in your own words.]

---

## Aza Mohanty

**Roles:** Quality & Accessibility Lead (to 10/15), then Product & UX Liaison (from 10/16).

**What I built (iOS)**
- Employee detail edits and employee ID display (10/16, 11/03).
- Reviewed and merged 4 PRs, including the Employee, Inventory, and Order data models (PR #8).
- [Add any iOS work that never reached GitHub, such as the early list view example, and say why.]

**What I built (Android)**
- Default image placeholder for products with no image (10/22).
- Order history and order details screens, rebuilt without `MyOrders` (10/26 to 10/28).
- Order screen design and a shared date formatter (11/02).
- Orders grouped by order number, with status, the customer name passed through state, and newest/oldest sort (11/10 to 11/18).
- Fixed the order repository and build errors before the final merge (11/14, 11/18).
- Merged the most Android PRs (9).

**What I learned:** [One or two sentences in your own words.]
