-- 06c_weekly_completion.sql
-- Weekly checkout completion by visitor type. The first week (Oct 26) holds only Nov 1; ignore it.
SELECT
  DATE_TRUNC(session_date, WEEK(MONDAY)) AS week,
  visitor_type,
  SUM(checkout_sessions) AS checkout_sessions,
  ROUND(SAFE_DIVIDE(SUM(completed_checkout_sessions), SUM(checkout_sessions)) * 100, 1) AS completion_pct
FROM `ga4-portfolio-509112.ga4_analysis.daily_metrics`
GROUP BY week, visitor_type
ORDER BY week, visitor_type;
