# GA4 ecommerce sample: what drives conversion, and a tracking break

**Data:** Public GA4 sample export from the Google Merchandise Store (BigQuery). Self-directed project, not client work.
**Window:** Nov 1, 2020 to Jan 25, 2021. Jan 26 to 31 is excluded from headline figures (see Finding 2). Revenue is in USD.
**Headline:** 337,693 sessions, 4,398 purchasing sessions (1.30%), $335,957 revenue ($0.995 per session).
**Tools:** BigQuery SQL, Data Studio (formerly Looker Studio) dashboard. Queries are in `/sql`, dashboard at [add link].

## Summary

Returning visitors are 27% of sessions but 63% of purchases, and the way they beat first-time visitors changed during the window. Purchases dropped about 80% from Jan 26 while traffic and checkout starts stayed normal, which looks like a tracking or site fault. Three data issues also change the headline numbers, the largest being a 7% revenue overstatement from repeat purchase events.

## Finding 1: Returning visitors drive most of the value, and the gap moved

| | First-time | Returning | Gap |
|---|---|---|---|
| Share of sessions | 72.5% | 27.5% | |
| Share of purchases | 37.1% | 62.9% | |
| Share of revenue | 33.2% | 66.8% | |
| Conversion | 0.67% | 2.98% | 4.5x |
| Sessions that start checkout | 2.36% | 5.22% | 2.2x |
| Checkout completion | 28.3% | 57.1% | 2.0x |
| Revenue per purchasing session | $68 | $81 | 1.2x |
| Revenue per session | $0.45 | $2.42 | 5.3x |

Over the whole window the conversion gap splits about evenly between entering checkout and finishing it. That split is not stable. By week:

| Week of | First-time entry | Returning entry | First-time completion | Returning completion |
|---|---|---|---|---|
| Nov 2 | 3.4% | 3.7% | 15.1% | 52.4% |
| Dec 14 | 1.8% | 6.5% | 41.7% | 60.8% |
| Jan 18 | 1.6% | 5.3% | 42.3% | 58.0% |

First-time completion rose from 15% to a plateau of 37 to 43% from mid-December, while first-time checkout entry fell from 3 to 4% in November to about 1% by late December. Returning visitors stayed in a narrower band. The overall conversion gap stayed roughly 3x to 7x in every full week, and that is the part I would rely on.

**Two explanations fit the entry drop, and this data cannot separate them:** seasonal browsing behavior, or a change in when `begin_checkout` fires. Conversion does not depend on that event and also moved with the holidays in both groups, so seasonality is at least part of it.

**Proposed test.** First confirm with engineering whether `begin_checkout` tracking changed in December. Then test guest checkout or a shorter form for first-time visitors only, randomized at checkout entry. Primary metric: checkout completion. Guardrails: revenue per checkout session and order value. By my rough calculation, detecting a 5-point lift from a 40% baseline needs about 1,500 checkout sessions per arm. First-time visitors produced roughly 125 to 800 checkout starts a week in this window, so expect anywhere from 4 to 12 weeks. Guest checkout is my hypothesis. I do not know this store's checkout flow.

**Caveats.** This is correlation: returning visitors arrive with more intent. "First-time" means GA session number 1 for a pseudonymous ID, so returning users who cleared cookies are counted as new.

## Finding 2: Purchases fall about 80% from Jan 26

| Period | Checkout starts | Completed | Completion |
|---|---|---|---|
| Jan 18 to 25 | 768 | 396 | 51.6% |
| Jan 26 to 31 | 496 | 48 | 9.7% |

**Confirmed:** daily completion goes 23% (Jan 26), 10%, 6%, then 0% on Jan 31. Sessions stay between 2,841 and 4,599 a day and checkout starts stay near their earlier level. Purchases equal completed checkouts every day, so it is purchases that disappear, not one funnel step.

**Inferred:** the cause is either the purchase tag failing or checkout breaking. This dataset has no order system behind it, so it cannot tell which. The 28 purchases on Jan 27 to 30 average about half the earlier value (small sample). Jan 27 also had more sessions without a `session_start` event than any other day (328); I did not test whether that is related.

**Size (rough estimate):** about 250 purchases expected at the Jan 18 to 25 rate against 48 observed, so about 200 missing. That is roughly 4% of the window's purchases and about $15,000 at the $76 average.

**Recommendation:** alert when daily checkout completion is more than 20 points below its trailing 14-day average for two days running. The threshold needs tuning, because daily values before the break wobbled by about 10 points. In a real setting, check the release log for Jan 25 and 26 and fire a test order.

## Finding 3: Data issues that change the headline numbers

| Issue | Size | Handling |
|---|---|---|
| Repeat purchase events | Summing them gives $362,165 vs $338,108 deduplicated (7.1% overstated, full window) | Deduplicated by transaction ID within session |
| Purchase events with no transaction ID | 906 of 5,692 events (16%) | Kept when they carried revenue; 402 sessions whose only purchase had no ID and no revenue are not counted (1.23% vs 1.35% raw, full window) |
| Transaction IDs in more than one session | 15 | Not deduplicated across sessions; under 0.3% of revenue |
| `add_to_cart` unreliable | Only 54% of checkout sessions have one in the same session; 38% of first-time purchases have none | Funnel built on `view_item`, `begin_checkout`, `purchase` |
| Traffic source | 119,125 of 360,129 sessions (33%) have source `<Other>` or `(data deleted)`; source is first touch, not session-level | No channel ranking; paid vs organic conversion is indistinguishable (0.92% ±0.15 vs 1.03% ±0.06, full window) |
| Sessions without `session_start` | 5,272 (1.5%), clustered on a few days, cause unknown | Kept; they convert at 1.63% vs 1.23% (86 purchases) and sessions are keyed on user ID plus session ID |

## What did not explain conversion

Device. Over the window, desktop converts at 1.28% and mobile at 1.34%, a gap within noise. Tablet has about 90 purchases, too few to read.

## Reproduce

`sql/01` to `sql/07` build and query the session table in order. `01b` and `05b` to `05d` are the checks behind the caveats above. The dashboard reads a small aggregated table (`daily_metrics`), and every rate is calculated as a ratio of sums.
