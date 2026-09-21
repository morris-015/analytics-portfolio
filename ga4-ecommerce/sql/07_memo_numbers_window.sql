-- 07_memo_numbers_window.sql
-- Headline figures for the memo and dashboard: Nov 1 2020 to Jan 25 2021 (excludes the Jan 26 to 31 break).
-- Expected ALL row: 337,693 sessions; 4,398 purchased; $335,957 revenue; 1.30% conversion.
SELECT
  IF(GROUPING(visitor_type) = 1, 'ALL', visitor_type) AS segment,
  SUM(sessions) AS sessions,
  SUM(checkout_sessions) AS checkout_sessions,
  SUM(completed_checkout_sessions) AS completed,
  SUM(purchased_sessions) AS purchased,
  ROUND(SUM(revenue_usd)) AS revenue_usd,
  ROUND(SAFE_DIVIDE(SUM(purchased_sessions), SUM(sessions)) * 100, 2) AS conv_pct,
  ROUND(SAFE_DIVIDE(SUM(checkout_sessions), SUM(sessions)) * 100, 2) AS entry_pct,
  ROUND(SAFE_DIVIDE(SUM(completed_checkout_sessions), SUM(checkout_sessions)) * 100, 1) AS completion_pct,
  ROUND(SAFE_DIVIDE(SUM(revenue_usd), SUM(sessions)), 3) AS rev_per_session
FROM `ga4-portfolio-509112.ga4_analysis.daily_metrics`
WHERE session_date <= DATE '2021-01-25'
GROUP BY ROLLUP(visitor_type)
ORDER BY sessions DESC;
