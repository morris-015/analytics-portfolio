-- 00_schema_checks.sql
-- Confirm the funnel events and session keys exist before building anything.

-- A: event names and volumes
SELECT
  event_name,
  COUNT(*) AS events,
  COUNT(DISTINCT user_pseudo_id) AS users
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
GROUP BY event_name
ORDER BY events DESC;

-- B: event_params keys (looking for ga_session_id and ga_session_number)
SELECT
  ep.key,
  COUNT(*) AS n
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
  UNNEST(event_params) AS ep
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
GROUP BY ep.key
ORDER BY n DESC
LIMIT 30;
