-- 03_funnel_by_device.sql
SELECT
  IF(GROUPING(device_category) = 1, 'ALL', device_category) AS device,
  COUNT(*) AS sessions,
  COUNTIF(purchased) AS purchased,
  ROUND(SAFE_DIVIDE(COUNTIF(purchased), COUNT(*)) * 100, 2) AS conv_pct,
  COUNTIF(viewed_item AND added_to_cart AND began_checkout AND purchased) AS strict_purchase,
  ROUND(SAFE_DIVIDE(COUNTIF(purchased AND began_checkout), COUNTIF(began_checkout)) * 100, 1) AS checkout_to_purchase_pct,
  ROUND(SAFE_DIVIDE(SUM(revenue_usd), COUNT(*)), 3) AS rev_per_session
FROM `ga4-portfolio-509112.ga4_analysis.sessions`
GROUP BY ROLLUP(device_category)
ORDER BY sessions DESC;
