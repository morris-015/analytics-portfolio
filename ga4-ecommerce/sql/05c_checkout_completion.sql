-- 05c_checkout_completion.sql
-- Full window (includes Jan 26 to 31). Completion is per session.
WITH t AS (
  SELECT
    IF(ga_session_number = 1, 'new', 'returning') AS visitor_type,
    COUNT(*) AS sessions,
    COUNTIF(began_checkout) AS checkout_sessions,
    COUNTIF(began_checkout AND purchased) AS completed
  FROM `ga4-portfolio-509112.ga4_analysis.sessions`
  GROUP BY visitor_type
)
SELECT
  visitor_type, sessions, checkout_sessions, completed,
  ROUND(checkout_sessions / sessions * 100, 2) AS checkout_entry_pct,
  ROUND(completed / checkout_sessions * 100, 1) AS completion_pct,
  ROUND(1.96 * SQRT((completed / checkout_sessions) * (1 - completed / checkout_sessions)
        / checkout_sessions) * 100, 1) AS completion_ci_pts
FROM t;
