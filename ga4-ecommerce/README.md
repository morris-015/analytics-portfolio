# GA4 ecommerce: conversion analysis

Self-directed analysis of Google's public GA4 sample dataset (Google Merchandise Store, Nov 2020 to Jan 2021). Built to practice product analytics: session-level SQL, funnel analysis, anomaly checks and a dashboard.

**Dashboard:** [https://datastudio.google.com/reporting/b2169a45-7d5e-4fcf-8ca9-61513fecc26f] (Data Studio, formerly Looker Studio)
**Memo:** [memo.md](memo.md) has three findings, each with evidence and a proposed next step.

## Results in brief

- Returning visitors are 27% of sessions but 63% of purchases and 67% of revenue. They convert at 2.98% against 0.67% for first-time visitors, and the split between entering and finishing checkout moved during the window.
- From Jan 26, purchases drop about 80% while sessions and checkout starts stay normal. Cause unknown (tracking or site fault). Headline figures cover Nov 1 to Jan 25 and exclude these days.
- Summing purchase events overstates revenue by 7.1% (repeat events). Traffic source is unusable for about a third of sessions, and `add_to_cart` is unreliable as a funnel step.

## How it is built

Raw GA4 events are reduced to one row per session (`user_pseudo_id` plus `ga_session_id`), then to a small daily table that the dashboard reads. Every dashboard rate is calculated as a ratio of sums, never an average of percentages.

| File | Purpose |
|---|---|
| `00_schema_checks.sql` | Confirm funnel events and session keys exist |
| `01_sanity_check.sql`, `01b_purchase_dedupe.sql` | Reconcile raw counts; find the purchase-event duplication |
| `02_build_sessions.sql` | Build the session table |
| `03` to `05d` | Funnel by device, conversion by source, new vs returning, and checks on the caveats |
| `06` to `06e` | Dashboard table, reconciliation, weekly completion and entry, the Jan 26 break |
| `07_memo_numbers_window.sql` | Headline figures used in the memo |

## Data notes

- Purchase events are deduplicated by transaction ID within a session. 906 of 5,692 purchase events have no ID and are handled separately (see `01b` and `02`).
- 15 transaction IDs appear in more than one session and are not deduplicated across sessions (under 0.3% of revenue).
- 5,272 sessions (1.5%) have no `session_start` event. They are kept, and sessions do not depend on that event.
- Source and medium are user-level first touch, not session-level.
- Revenue is in USD.

## Limits

- Public sample data, not production data. Findings describe this sample, not a real business.
- New vs returning uses GA session number, so returning users with a reset ID count as new. The comparison is correlation, not proof that getting visitors back causes purchases.
- The dashboard is built in Data Studio (formerly Looker Studio). It is not Looker and uses no LookML.

## Reproduce

Create a BigQuery dataset named `ga4_analysis` in the US multi-region, replace the project ID `ga4-portfolio-509112` in the queries with your own, and run the files in order. Only `00`, `01`, `01b` and `02` read the raw events. The rest read the small tables.
