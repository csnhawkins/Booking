# GitHub issue copy - slow flight search

Paste the title and body into a new GitHub issue. Replace the items in [square brackets] with real
values before publishing (Monitor numbers must come from the real system, not be estimated).

Suggested labels: `performance`, `database`, `copilot`
Suggested project board column: Ready

---

## Title

Flight search is slow since the partial-match release (usp_SearchFlights)

## Body

### Summary

Since BOOK-214 (flexible flight search) went live, `Logistics.usp_SearchFlights` has become one of
the most expensive queries on the Booking database. Customers are seeing slow results on the flight
search page, particularly at peak times.

### Evidence

- Redgate Monitor top queries: `usp_SearchFlights` is [rank / avg duration / executions per hour].
- Before BOOK-214 (V002) average duration was [x]; after (V015) it is [y].
- Monitor deployment annotation for V015 shows the change in [date/time].
- [Optional: screenshot of the Monitor top queries view]

### Suspected causes

Based on a read of the current definition (`schema-model/Stored Procedures/Logistics.usp_SearchFlights.sql`):

- The city filters wrap the column in `LOWER()` and use a leading wildcard, so the index on
  `Logistics.Flight (DepartureCity, ArrivalCity, DepartureTime)` cannot be used for a seek.
- `FlightsEarlierOnRoute` is a correlated subquery that runs for every returned row.
- The `Logistics.FlightMaintenanceStatus` view aggregates every flight and maintenance log before it
  is joined.

These are suspicions to confirm, not instructions. Please verify before changing anything.

### What needs to happen

Fix the slow query without breaking what BOOK-214 delivered.

### Acceptance criteria

- [ ] Typing a partial, mixed-case city such as "lon" or "new york" still returns matching flights.
- [ ] The result set keeps the same columns, names and types.
- [ ] `FlightsEarlierOnRoute` returns the same values as today, or any difference is called out
      explicitly in the PR for sign-off.
- [ ] `MaintenanceCount` returns the same values as today.
- [ ] The query no longer scans the whole `Logistics.Flight` table for a typical search.
- [ ] Results remain ordered cheapest first.
- [ ] The change is delivered as a schema-model update, with the migration and undo scripts generated
      by Flyway (not hand-written).
- [ ] Migrate and undo both pass against the shadow database, and Flyway code review checks pass or
      each finding is explained.

### Out of scope

- Changing the web front end.
- Adding paging back (separate discussion with Product).

### How this will be delivered

Assigned to Copilot. Copilot updates the schema-model on a branch and opens a PR. The Flyway MCP
generates and validates the migration, and Copilot summarises the result for the approver. Merging
to `main` runs the Flyway pipeline (Build, Test, Production) including the Check report.
