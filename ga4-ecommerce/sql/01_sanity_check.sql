-- 01_sanity_check.sql
-- Reconciliation checks on the raw GA4 export, Nov 1 2020 to Jan 31 2021.
-- Finding: 5,692 purchase events vs 4,451 distinct real transaction IDs;
-- 906 purchase events have no usable ID. See 01b_purchase_dedupe.sql.
SELECT
  COUNT(*) AS events,
  COUNT(DISTINCT user_pseudo_id) AS users,
  COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS STRING))) AS sessions,
  COUNTIF(event_name = 'session_start') AS session_start_events,
  COUNTIF(event_name = 'purchase') AS purchase_events,
  COUNT(DISTINCT IF(event_name = 'purchase', ecommerce.transaction_id, NULL)) AS distinct_transactions,
  SUM(IF(event_name = 'purchase', ecommerce.purchase_revenue_in_usd, 0)) AS revenue_usd
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131';
