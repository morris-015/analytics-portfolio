-- 06_dashboard_table.sql
-- Small aggregated table for the dashboard. Stores counts, not rates:
-- rates are calculated in the dashboard as ratios of sums.
CREATE OR REPLACE TABLE `ga4-portfolio-509112.ga4_analysis.daily_metrics` AS
SELECT
  session_date,
  device_category,
  IF(ga_session_number = 1, 'new', 'returning') AS visitor_type,
  CASE
    WHEN source = '(data deleted)' THEN 'data deleted'
    WHEN source = '<Other>' AND medium = '<Other>' THEN 'obfuscated'
    WHEN source LIKE 'shop.googlemerchandisestore%' THEN 'shop domain referral'
    WHEN source = '(direct)' THEN 'direct'
    WHEN source = 'google' AND medium = 'organic' THEN 'google organic'
    WHEN source = 'google' AND medium = 'cpc' THEN 'google cpc'
    WHEN medium = 'referral' THEN 'other referral'
    ELSE 'other'
  END AS source_group,  -- user-level first touch, not session-level
  COUNT(*) AS sessions,
  COUNTIF(viewed_item) AS viewed_item_sessions,
  COUNTIF(began_checkout) AS checkout_sessions,
  COUNTIF(purchased) AS purchased_sessions,
  COUNTIF(began_checkout AND purchased) AS completed_checkout_sessions,
  ROUND(SUM(revenue_usd), 2) AS revenue_usd
FROM `ga4-portfolio-509112.ga4_analysis.sessions`
GROUP BY session_date, device_category, visitor_type, source_group;
