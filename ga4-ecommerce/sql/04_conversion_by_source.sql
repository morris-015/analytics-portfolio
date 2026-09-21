-- 04_conversion_by_source.sql
-- source/medium is user-level first touch, not session-level
SELECT
  IFNULL(source, '(null)') AS source,
  IFNULL(medium, '(null)') AS medium,
  COUNT(*) AS sessions,
  COUNTIF(purchased) AS purchased,
  ROUND(SAFE_DIVIDE(COUNTIF(purchased), COUNT(*)) * 100, 2) AS conv_pct,
  -- 95% interval half-width in points (normal approximation, treats sessions as independent)
  ROUND(1.96 * SQRT(SAFE_DIVIDE(COUNTIF(purchased), COUNT(*))
        * (1 - SAFE_DIVIDE(COUNTIF(purchased), COUNT(*))) / COUNT(*)) * 100, 2) AS ci_pts,
  ROUND(SUM(revenue_usd)) AS revenue_usd,
  ROUND(SAFE_DIVIDE(SUM(revenue_usd), COUNT(*)), 3) AS rev_per_session
FROM `ga4-portfolio-509112.ga4_analysis.sessions`
GROUP BY source, medium
HAVING COUNT(*) >= 2000
ORDER BY sessions DESC;
