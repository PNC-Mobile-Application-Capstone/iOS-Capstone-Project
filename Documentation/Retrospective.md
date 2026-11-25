# Final Retrospective

**Project:** AdventureWorks Mobile (iOS) and AdventureWorks Customer Companion (Android)
**Date:** [Fill in the retro date]
**Facilitator:** Tyler Swindell
**Attendees:** Tyler, Nathan, Aza, Jonah
**Format:** Went well, Was hard, Change next time. Each person adds notes, then the team votes on one lesson for the presentation.

> **Draft.** This was built from the repo history, meeting notes, and status reviews. Each member should add or cut points during the retro meeting. Keep only what the team agrees on.

---

## What Went Well

- **"Build one, copy the pattern."** On iOS, one list and one detail screen were finished first as examples. `PageTemplate` and the generic `TieredCacheRepositoryBase` came out of that. Later screens (Inventory, Orders, Employees) went much faster.
- **One generic repository on iOS.** Four separate cache classes were folded into one generic class on 10/10. Every list got caching and offline support for free.
- **Token renewal was tested early.** It was built and unit tested in Sprint 1. It never broke later, which is why we picked it as a choice feature.
- **Android Sprint 0.** We set up the repo, the library list, and the Definition of Done before writing features. Two pairs then built vertical slices (Catalog and Orders) in parallel.
- **Tests on Android.** About 170 unit tests and 5 instrumented Room tests. Fakes made ViewModel tests fast.
- **Every change went through a reviewed PR.** All four members have commits and merged PRs in both repos.

## What Was Hard

- **Definition of Done came late on iOS.** We agreed on it in Meeting 4 (10/09), after coding had started. Some early screens had to be reworked to meet it ("ERROR" text, missing labels, nested `NavigationStack`s).
- **Guessing API fields.** Models were written before we checked Swagger. Fields that were sometimes null crashed whole lists until we switched to optional decoding.
- **Merge pain.** Work started on the wrong branch, a merge brought back a logout bug, and a conflict marker was committed once. Long-lived branches made this worse.
- **Work not pushed early.** Some work sat on laptops for days. Teammates could not see it or build on it, and the status reviews could not count it.
- **No answers from the Product Owner.** Questions about roles, the weekly sales range, and order audience never got an answer. We made our own calls and wrote them down.
- **Two apps at once.** Android started 10/16 while iOS still had open items. Shared items like the shared loading and error view on iOS kept slipping.

## What We Would Change Next Time

1. **Write the Definition of Done before any code.** Android proved it: reviews went faster because everyone checked the same list.
2. **Open Swagger before writing a model.** Write down real field names and which ones can be null.
3. **Push small branches daily, even unfinished.** A draft PR is better than a laptop-only change.
4. **Build shared pieces first.** A shared loading, empty, and error view should exist before the second screen.
5. **Set a deadline for Product Owner answers.** If there is no answer by then, decide, write it down, and move on.

## Lesson for the Presentation (Slide 14)

**We wrote our Definition of Done after coding started on iOS. On Android we wrote it in Sprint 0, and reviews went faster.**

[Team: vote to keep this one or pick another.]

## Action Items

| Action | Owner | Due |
| --- | --- | --- |
| Add a shared loading, empty, and error view with Retry on iOS | [Owner] | [Date] |
| Merge the "Last updated" / offline label on iOS | Tyler | [Date] |
| Switch Android order money to `BigDecimal` | [Owner] | [Date] |
| Save the final board screenshots | Tyler | Before the presentation |
