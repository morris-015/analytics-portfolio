-- 06d_late_jan_daily.sql
-- The break: daily checkout completion from Jan 18. Completion falls from ~50% to ~10% after Jan 25.
SELECT
  session_date,
  SUM(sessions) AS sessions,
  SUM(checkout_sessions) AS checkouts,
  SUM(completed_checkout_sessions) AS completed,
  ROUND(SAFE_DIVIDE(SUM(completed_checkout_sessions), SUM(checkout_sessions)) * 100, 1) AS completion_pct,
  SUM(purchased_sessions) AS purchased,
  ROUND(SAFE_DIVIDE(SUM(revenue_usd), SUM(purchased_sessions)), 1) AS rev_per_purchase
FROM `ga4-portfolio-509112.ga4_analysis.daily_metrics`
WHERE session_date >= DATE '2021-01-18'
GROUP BY session_date
ORDER BY session_date;
