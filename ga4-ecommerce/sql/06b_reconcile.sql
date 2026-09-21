-- 06b_reconcile.sql
-- Expected ALL row: 360,129 sessions; 4,446 purchased; $338,108 revenue.
SELECT
  IF(GROUPING(source_group) = 1, 'ALL', source_group) AS channel,
  SUM(sessions) AS sessions,
  SUM(purchased_sessions) AS purchased,
  ROUND(SUM(revenue_usd)) AS revenue_usd,
  COUNT(*) AS table_rows
FROM `ga4-portfolio-509112.ga4_analysis.daily_metrics`
GROUP BY ROLLUP(source_group)
ORDER BY sessions DESC;
