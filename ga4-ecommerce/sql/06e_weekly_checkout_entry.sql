-- 06e_weekly_checkout_entry.sql
-- Weekly share of sessions that begin checkout, new vs returning.
SELECT
  DATE_TRUNC(session_date, WEEK(MONDAY)) AS week,
  ROUND(SAFE_DIVIDE(SUM(IF(visitor_type = 'new', checkout_sessions, 0)),
                    SUM(IF(visitor_type = 'new', sessions, 0))) * 100, 2) AS new_entry_pct,
  ROUND(SAFE_DIVIDE(SUM(IF(visitor_type = 'returning', checkout_sessions, 0)),
                    SUM(IF(visitor_type = 'returning', sessions, 0))) * 100, 2) AS ret_entry_pct
FROM `ga4-portfolio-509112.ga4_analysis.daily_metrics`
GROUP BY week
ORDER BY week;
