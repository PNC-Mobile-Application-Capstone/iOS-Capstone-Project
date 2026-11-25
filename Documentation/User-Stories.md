# User Stories: AdventureWorks Mobile (iOS)

**Status as of:** Wed 11/18/26, `dev` at `34cf0d4`
**Users:** store employees and managers. The API has no role flag, so both see the same app.
**Priority key:** P1 = blocks other work. P2 = required feature. P3 = choice feature or polish.
**Status key:** Done. Partial (works, misses part of a criterion). Not done.

Each story lists at least one unhappy path, as the Definition of Ready requires.

---

## Req 1. Secure Sign-In and Session (P1, Nathan and Tyler). Status: Done

**Story:** As an employee, I want to sign in once and stay signed in, so that I can check store data fast without typing my password every time.

| # | Acceptance criterion | Status |
|---|---|---|
| 1.1 | Given valid credentials, when I tap Sign In, then I see the Dashboard. | Done |
| 1.2 | Given I closed the app while signed in, when I reopen it, then I am still signed in. | Done |
| 1.3 | Given I tap Log Out in Account, then both tokens are deleted and I see the sign-in screen. | Done |
| 1.4 | **Unhappy:** Given a wrong password, then I see a plain "check your username and password" message, not a code. | Done |
| 1.5 | **Unhappy:** Given no one is signed in, then no tab or screen can be reached. | Done (UI test) |
| 1.6 | Tokens are stored in Keychain, never in UserDefaults or logs. | Done |

## Req 2. Operational Dashboard (P2, Jonah). Status: Partial

**Story:** As a manager, I want sales, top and weak products, low stock, and today's shifts on one screen, so that I know what needs attention when I walk in.

| # | Acceptance criterion | Status |
|---|---|---|
| 2.1 | The dashboard shows weekly sales, best and worst products, low stock, and shifts from live API data. | Done |
| 2.2 | Weekly sales shows as a bar chart with VoiceOver labels. | Done |
| 2.3 | Tapping a product, employee, or low-stock item opens its detail screen. | Done |
| 2.4 | More than one strong and one weak product are shown. | Not done (one each) |
| 2.5 | Pull down to refresh reloads all four sections. | Done |
| 2.6 | **Unhappy:** Given one dashboard call fails, then the other sections still show and a message says some data could not update. | Done (one shared message) |
| 2.7 | **Unhappy:** Given the app launches offline, then the last saved dashboard shows. | Done |

## Req 3. Employee Directory and Profile (P2, Tyler, Aza, Jonah). Status: Partial

**Story:** As a manager, I want to find an employee and see their role, department, shift, and history, so that I can reach the right person.

| # | Acceptance criterion | Status |
|---|---|---|
| 3.1 | The list shows name, department, and job title, so similar names can be told apart. | Done |
| 3.2 | The profile shows department, job title, shift, formatted hire date, and tenure. | Done |
| 3.3 | The profile shows employment history from `GET /api/Employee/{id}`. | Done |
| 3.4 | I can search and sort the employee list. | Done |
| 3.5 | **Unhappy:** Given a field is blank, then I see "--", not "ERROR" or a crash. | Done |
| 3.6 | The employee repository has unit tests. | Not done |

## Req 4. Search, Sort, or Filter (P2, Nathan). Status: Done

**Story:** As an employee, I want to search and sort long lists, so that I find a product or order in seconds.

| # | Acceptance criterion | Status |
|---|---|---|
| 4.1 | Products: search by name or number, sort by name or price. | Done |
| 4.2 | Orders: search by customer or number, sort by number, newest, or oldest. | Done |
| 4.3 | Inventory and Employees: search. | Done |
| 4.4 | The active search or sort is visible on screen. | Done |
| 4.5 | One Clear control resets search and sort. | Done |
| 4.6 | **Unhappy:** Given no matches, then I see "No results," not a blank list. | Done |

## Req 5. Product Catalog and Details (P2, Tyler and Jonah). Status: Partial

**Story:** As an employee, I want to browse products and see full details, so that I can answer customer questions on the floor.

| # | Acceptance criterion | Status |
|---|---|---|
| 5.1 | The list shows name, number, and price in US currency, and loads more as I scroll. | Done |
| 5.2 | Details show labeled values: overview, specs, warranty and maintenance, manufacturing. | Done |
| 5.3 | The product photo shows, or a placeholder icon when there is none. | Done |
| 5.4 | Product Line codes show full names. | Partial ("S" shows as "S") |
| 5.5 | **Unhappy:** Given a missing field, then a placeholder shows, never "ERROR." | Done |

## Req 6. Inventory Awareness (P2, Tyler). Status: Done

**Story:** As a manager, I want to see stock by location with a clear warning when it is low, so that I reorder before we run out.

| # | Acceptance criterion | Status |
|---|---|---|
| 6.1 | Inventory is grouped by location, with a count of items that need reorder. | Done |
| 6.2 | Each row shows quantity, reorder point, shelf, and bin. | Done |
| 6.3 | Status shows an icon plus a word (Out of stock, Critical, Reorder, Low, In stock), never color alone. | Done |
| 6.4 | VoiceOver reads one summary per row. | Done |
| 6.5 | **Unhappy:** Given a null field, then the row still loads. Rows are keyed by product plus location, so they never collide. | Done |

## Req 7. Order Exploration (P2, Tyler and Aza). Status: Done

**Story:** As an employee, I want to look up a customer order and its line items, so that I can answer "where is my order" questions.

| # | Acceptance criterion | Status |
|---|---|---|
| 7.1 | Customer orders are grouped by order number. | Done |
| 7.2 | The list shows order number, customer, date, and total. | Done |
| 7.3 | The detail shows every line (quantity times price), product count, units, and total. | Done |
| 7.4 | Tapping a line opens that product. | Done |
| 7.5 | **Unhappy:** Given no ship date, then the order still loads. | Done |

## Req 8. Refresh and Current-State Feedback (P2, Jonah and Tyler). Status: Partial

**Story:** As an employee, I want to know when data is loading, empty, or failed, so that I never wonder if the app is stuck.

| # | Acceptance criterion | Status |
|---|---|---|
| 8.1 | Pull to refresh on every list, the dashboard, and detail screens. | Done |
| 8.2 | A spinner shows on the first load. | Partial (detail screens only) |
| 8.3 | An empty list shows a message, not a blank screen. | Partial (search only) |
| 8.4 | **Unhappy:** Given I pull to refresh twice fast, then only one request runs. | Not done |

## Req 9. Failure Recovery and Partial Availability (P2, everyone). Status: Partial

**Story:** As an employee on weak store Wi-Fi, I want the app to keep working when a call fails, so that one bad request does not block my work.

| # | Acceptance criterion | Status |
|---|---|---|
| 9.1 | Each tab loads on its own. One failed tab does not affect the others. | Done |
| 9.2 | Given the API fails and saved data exists, then the saved data shows. | Done |
| 9.3 | Errors show plain words, not system text. | Partial (network errors only) |
| 9.4 | A failed screen offers a clear way to try again. | Partial (pull to refresh, no Retry button) |
| 9.5 | The app never crashes or spins forever on a failed call. | Done |

## Req 10. Accessible and Adaptable Interface (P2, Aza then Jonah). Status: Partial

**Story:** As an employee who uses VoiceOver or large text, I want every screen to read clearly and fit the screen, so that I can use the app like anyone else.

| # | Acceptance criterion | Status |
|---|---|---|
| 10.1 | Every accessibility ID is unique. | Done |
| 10.2 | Every row, button, and chart has a VoiceOver label. | Partial (Inventory, Employee header, chart) |
| 10.3 | All screens work at the largest Dynamic Type size. | Partial (Inventory checked) |
| 10.4 | No meaning is carried by color alone. | Done |
| 10.5 | Tested on the smallest and largest supported iPhone. | Not done |

## Choice 13. Token Renewal (P3, Tyler). Status: Done

**Story:** As an employee, I want my session to renew on its own, so that I am not kicked out in the middle of a task.

| # | Acceptance criterion | Status |
|---|---|---|
| 13.1 | Given a call returns 401, then the app refreshes the token once and retries the call once. | Done (unit test) |
| 13.2 | **Unhappy:** Given the refresh fails, then I am signed out with "session expired." No loop. | Done (unit test) |

## Choice 14. Local Continuity (P3, Tyler). Status: Partial

**Story:** As an employee in a dead zone, I want to see the last data I loaded, so that I can keep working offline.

| # | Acceptance criterion | Status |
|---|---|---|
| 14.1 | Data loads from memory, then Core Data, then the API, each fresh for 15 minutes. | Done (unit test) |
| 14.2 | Given I am offline, then the last saved list shows. | Done |
| 14.3 | Saved data is marked so it never looks current ("Last updated" or "Offline, showing saved data"). | Not done (in progress) |

---

## Not Built (Icebox)

- **Choice 11, Inventory adjustment.** Needs a role to decide who is "authorized." The API has none.
- **Choice 12, Employee info update.** New work from scratch, and the same open question about who may edit.
