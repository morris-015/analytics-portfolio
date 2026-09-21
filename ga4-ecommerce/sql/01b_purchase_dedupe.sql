-- 01b_purchase_dedupe.sql
-- Why purchase events cannot be summed as-is.

-- Query 1: how many purchase events lack a usable transaction ID?
WITH p AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS sid,
    ecommerce.transaction_id AS txn,
    ecommerce.purchase_revenue_in_usd AS rev
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name = 'purchase'
)
SELECT
  COUNT(*) AS purchase_events,
  COUNTIF(txn IS NULL OR txn = '(not set)') AS unset_txn_events,
  COUNT(DISTINCT IF(txn IS NULL OR txn = '(not set)', NULL, txn)) AS distinct_real_txn,
  COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(sid AS STRING))) AS purchasing_sessions,
  COUNTIF(rev IS NULL OR rev = 0) AS zero_or_null_rev_events,
  SUM(rev) AS rev_all_events
FROM p;

-- Query 2: classify purchasing sessions by pattern and compare two ways of summing revenue
WITH p AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS sid,
    IF(ecommerce.transaction_id IS NULL OR ecommerce.transaction_id = '(not set)',
       NULL, ecommerce.transaction_id) AS txn,
    ecommerce.purchase_revenue_in_usd AS rev
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name = 'purchase'
),
s AS (
  SELECT
    user_pseudo_id, sid,
    COUNT(*) AS n_events,
    COUNT(DISTINCT txn) AS n_txn,
    COUNTIF(txn IS NULL) AS n_unset,
    COUNTIF(rev IS NULL OR rev = 0) AS n_zero_rev,
    COUNTIF(txn IS NULL AND (rev IS NULL OR rev = 0)) AS n_unset_and_zero,
    MAX(rev) AS max_rev,
    SUM(rev) AS sum_rev
  FROM p
  GROUP BY user_pseudo_id, sid
)
SELECT
  CASE
    WHEN n_events = 1 AND n_unset = 0 THEN '1_single_real_txn'
    WHEN n_events = 1 THEN '2_single_unset_txn'
    WHEN n_txn >= 2 THEN '3_multiple_real_txn'
    WHEN n_txn = 1 AND n_unset = 0 THEN '4_repeat_same_txn'
    WHEN n_txn = 1 THEN '5_real_plus_unset'
    ELSE '6_multi_all_unset'
  END AS pattern,
  COUNT(*) AS sessions,
  SUM(n_events) AS events,
  SUM(n_zero_rev) AS zero_rev_events,
  SUM(n_unset_and_zero) AS unset_and_zero_events,
  SUM(sum_rev) AS rev_sum_all_events,
  SUM(max_rev) AS rev_max_per_session
FROM s
GROUP BY pattern
ORDER BY pattern;
