-- 05d_checkout_completion_by_user.sql
-- Users who began checkout in their first in-window session: did they buy in session 1, or only later?
-- Result: only ~3 points of extra completion come from later sessions, so first-time abandonment is mostly real.
WITH u AS (
  SELECT
    user_pseudo_id,
    MIN(IF(ga_session_number = 1, session_date, NULL)) AS first_date,
    LOGICAL_OR(ga_session_number = 1 AND began_checkout) AS checkout_s1,
    LOGICAL_OR(ga_session_number = 1 AND purchased) AS bought_s1,
    LOGICAL_OR(ga_session_number > 1 AND purchased) AS bought_later
  FROM `ga4-portfolio-509112.ga4_analysis.sessions`
  GROUP BY user_pseudo_id
)
SELECT
  first_date <= DATE '2020-12-15' AS first_seen_by_dec15,
  COUNT(*) AS users_checkout_s1,
  COUNTIF(bought_s1) AS bought_in_s1,
  COUNTIF(NOT bought_s1 AND bought_later) AS bought_later_only,
  ROUND(SAFE_DIVIDE(COUNTIF(bought_s1), COUNT(*)) * 100, 1) AS s1_completion_pct,
  ROUND(SAFE_DIVIDE(COUNTIF(bought_s1 OR bought_later), COUNT(*)) * 100, 1) AS ever_completed_pct
FROM u
WHERE checkout_s1
GROUP BY first_seen_by_dec15;
