-- 05b_cart_carryover.sql
-- Hypothesis tested: returning buyers build carts in earlier sessions.
-- Result: same-session cart share on checkout sessions is ~54% for both groups, so it does not explain the gap.
-- Side finding: 38% of first-time purchases have no add_to_cart event, so add_to_cart is unreliable as a funnel gate.
SELECT
  IF(ga_session_number = 1, 'new', 'returning') AS visitor_type,
  COUNTIF(began_checkout) AS checkout_sessions,
  ROUND(SAFE_DIVIDE(COUNTIF(began_checkout AND added_to_cart), COUNTIF(began_checkout)) * 100, 1) AS pct_checkout_with_cart_same_session,
  COUNTIF(purchased) AS purchases,
  ROUND(SAFE_DIVIDE(COUNTIF(purchased AND added_to_cart), COUNTIF(purchased)) * 100, 1) AS pct_purchases_with_cart_same_session
FROM `ga4-portfolio-509112.ga4_analysis.sessions`
GROUP BY visitor_type;
