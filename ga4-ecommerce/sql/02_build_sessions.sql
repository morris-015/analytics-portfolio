-- 02_build_sessions.sql
-- One row per session (user_pseudo_id + ga_session_id).
-- Purchases: repeat fires of one transaction are collapsed (see 01b);
-- source/medium are user-level first touch, not session-level.
CREATE OR REPLACE TABLE `ga4-portfolio-509112.ga4_analysis.sessions` AS
WITH ev AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS ga_session_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_number') AS ga_session_number,
    PARSE_DATE('%Y%m%d', event_date) AS event_date,
    event_name,
    device.category AS device_category,
    traffic_source.source AS source,
    traffic_source.medium AS medium,
    IF(ecommerce.transaction_id IS NULL OR ecommerce.transaction_id = '(not set)',
       NULL, ecommerce.transaction_id) AS txn,
    ecommerce.purchase_revenue_in_usd AS rev
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
),
-- Repeat fires of one transaction carry identical revenue (see 01b), so collapse to one row per transaction
real_txn AS (
  SELECT user_pseudo_id, ga_session_id, txn, MAX(rev) AS rev
  FROM ev
  WHERE event_name = 'purchase' AND txn IS NOT NULL
  GROUP BY user_pseudo_id, ga_session_id, txn
),
real_by_session AS (
  SELECT user_pseudo_id, ga_session_id,
         COUNT(*) AS n_real_txn,
         SUM(IFNULL(rev, 0)) AS rev_real
  FROM real_txn
  GROUP BY user_pseudo_id, ga_session_id
),
-- No transaction ID: separate orders can't be told apart, so keep the largest value per session.
-- In sessions that also have a real ID, the no-ID events are all $0 (checked in 01b), so no double count.
unset_by_session AS (
  SELECT user_pseudo_id, ga_session_id,
         MAX(IFNULL(rev, 0)) AS rev_unset
  FROM ev
  WHERE event_name = 'purchase' AND txn IS NULL
  GROUP BY user_pseudo_id, ga_session_id
),
base AS (
  SELECT
    user_pseudo_id,
    ga_session_id,
    MIN(ga_session_number) AS ga_session_number,
    MIN(event_date) AS session_date,
    ANY_VALUE(device_category) AS device_category,
    ANY_VALUE(source) AS source,   -- user-level first touch, not session-level
    ANY_VALUE(medium) AS medium,
    LOGICAL_OR(event_name = 'session_start') AS has_session_start,
    LOGICAL_OR(event_name = 'view_item') AS viewed_item,
    LOGICAL_OR(event_name = 'add_to_cart') AS added_to_cart,
    LOGICAL_OR(event_name = 'begin_checkout') AS began_checkout,
    LOGICAL_OR(event_name = 'purchase') AS purchased_raw
  FROM ev
  GROUP BY user_pseudo_id, ga_session_id
)
SELECT
  b.*,
  IFNULL(r.n_real_txn, 0) AS n_real_txn,
  (IFNULL(r.n_real_txn, 0) > 0 OR IFNULL(u.rev_unset, 0) > 0) AS purchased,
  IFNULL(r.rev_real, 0) + IFNULL(u.rev_unset, 0) AS revenue_usd
FROM base b
LEFT JOIN real_by_session r
  ON b.user_pseudo_id = r.user_pseudo_id AND b.ga_session_id = r.ga_session_id
LEFT JOIN unset_by_session u
  ON b.user_pseudo_id = u.user_pseudo_id AND b.ga_session_id = u.ga_session_id;

-- Validation (expected: 360,129 sessions; 4,848 purchased_raw; 4,446 purchased; ~$338,108 revenue)
SELECT
  COUNT(*) AS sessions,
  COUNTIF(NOT has_session_start) AS no_start_sessions,
  COUNTIF(purchased_raw) AS purchased_raw,
  COUNTIF(purchased) AS purchased,
  SUM(n_real_txn) AS real_txn,
  ROUND(SUM(revenue_usd)) AS revenue_usd
FROM `ga4-portfolio-509112.ga4_analysis.sessions`;
