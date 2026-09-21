-- 05_new_vs_returning.sql
SELECT
  IF(ga_session_number = 1, 'new', 'returning') AS visitor_type,
  COUNT(*) AS sessions,
  ROUND(SAFE_DIVIDE(COUNTIF(viewed_item), COUNT(*)) * 100, 1) AS view_item_pct,
  ROUND(SAFE_DIVIDE(COUNTIF(added_to_cart), COUNT(*)) * 100, 2) AS cart_pct,
  COUNTIF(purchased) AS purchased,
  ROUND(SAFE_DIVIDE(COUNTIF(purchased), COUNT(*)) * 100, 2) AS conv_pct,
  ROUND(1.96 * SQRT(SAFE_DIVIDE(COUNTIF(purchased), COUNT(*))
        * (1 - SAFE_DIVIDE(COUNTIF(purchased), COUNT(*))) / COUNT(*)) * 100, 2) AS ci_pts,
  ROUND(SAFE_DIVIDE(SUM(revenue_usd), COUNT(*)), 3) AS rev_per_session
FROM `ga4-portfolio-509112.ga4_analysis.sessions`
GROUP BY visitor_type;
