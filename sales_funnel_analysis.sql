SELECT * FROM user_events;
-- define period for sales:
SELECT MIN(event_date), MAX(event_date)
FROM user_events;

-- define sales funnel and stages
WITH funnel_stages AS(
	SELECT
		COUNT(DISTINCT (CASE WHEN event_type = "page_view" THEN user_id END)) AS stage_1_view,
        COUNT(DISTINCT (CASE WHEN event_type = "add_to_cart" THEN user_id END)) AS stage_2_cart,
        COUNT(DISTINCT (CASE WHEN event_type = "checkout_start" THEN user_id END)) AS stage_3_checkout,
        COUNT(DISTINCT (CASE WHEN event_type = "payment_info" THEN user_id END)) AS stage_4_payment,
        COUNT(DISTINCT (CASE WHEN event_type = "purchase" THEN user_id END)) AS stage_5_purchase
FROM user_events
)
SELECT * FROM funnel_stages;

-- conversion rate through stages
WITH funnel_stages AS(
	SELECT
		COUNT(DISTINCT (CASE WHEN event_type = "page_view" THEN user_id END)) AS stage_1_view,
        COUNT(DISTINCT (CASE WHEN event_type = "add_to_cart" THEN user_id END)) AS stage_2_cart,
        COUNT(DISTINCT (CASE WHEN event_type = "checkout_start" THEN user_id END)) AS stage_3_checkout,
        COUNT(DISTINCT (CASE WHEN event_type = "payment_info" THEN user_id END)) AS stage_4_payment,
        COUNT(DISTINCT (CASE WHEN event_type = "purchase" THEN user_id END)) AS stage_5_purchase
FROM user_events
)
SELECT 
	stage_1_view,
    stage_2_cart,
	ROUND(stage_2_cart * 100/stage_1_view,2) AS view_to_cart,
    
    stage_3_checkout,
    ROUND(stage_3_checkout * 100/stage_2_cart,2) AS cart_to_checkout,
    
    stage_4_payment,
    ROUND(stage_4_payment* 100/stage_3_checkout,2) AS checkout_to_payment,
    
    stage_5_purchase,
    ROUND(stage_5_purchase* 100/stage_4_payment,2) AS payment_to_purchase,
    ROUND(stage_5_purchase* 100/stage_1_view,2) AS overal_conversion
    
FROM funnel_stages;

-- funnel by source
WITH traffic_funnel AS(
	SELECT
		traffic_source,
		COUNT(DISTINCT (CASE WHEN event_type = "page_view" THEN user_id END)) AS views,
        COUNT(DISTINCT (CASE WHEN event_type = "add_to_cart" THEN user_id END)) AS cart,
        COUNT(DISTINCT (CASE WHEN event_type = "payment_info" THEN user_id END)) AS payment,
        COUNT(DISTINCT (CASE WHEN event_type = "purchase" THEN user_id END)) AS purchase
FROM user_events
GROUP BY traffic_source
)
SELECT 
	traffic_source,
	views,
    cart,
    payment,
	purchase,
	ROUND(purchase* 100/views,2) AS view_to_purchase_conversion
FROM traffic_funnel;

-- user journey time spent 
WITH time_spent AS(
	SELECT
		user_id,
		MIN(CASE WHEN event_type = "page_view" THEN event_date END) AS view_time,
        MIN(CASE WHEN event_type = "add_to_cart" THEN event_date END) AS cart_time,
        MIN(CASE WHEN event_type = "payment_info" THEN event_date END) AS payment_time,
        MIN(CASE WHEN event_type = "purchase" THEN event_date END) AS purchase_time
FROM user_events
GROUP BY user_id
HAVING MIN(CASE WHEN event_type = "purchase" THEN event_date END) IS NOT NULL
)
SELECT 
	COUNT(*) AS converted_users,
    ROUND(AVG(timestampdiff(MINUTE,view_time,cart_time)),2) AS view_cart_time_conversion,
    ROUND(AVG(timestampdiff(MINUTE,cart_time,payment_time)),2) AS cart_to_payment_time_conversion,
    ROUND(AVG(timestampdiff(MINUTE,payment_time,purchase_time)),2) AS payment_to_purchase_conversion,
    ROUND(AVG(timestampdiff(MINUTE,view_time,purchase_time)),2) AS overal_conversion_time
FROM time_spent;

-- funnel revenue
WITH revenue_funnel AS(
	SELECT
		traffic_source,
		COUNT(DISTINCT (CASE WHEN event_type = "page_view" THEN user_id END)) AS total_visits,
        COUNT(DISTINCT (CASE WHEN event_type = "purchase" THEN user_id END)) AS total_buyers,
        COUNT((CASE WHEN event_type = "purchase" THEN 1 END)) AS total_orders,
        ROUND(SUM(CASE WHEN event_type = "purchase" THEN amount END),2) AS sum_revenue
FROM user_events
GROUP BY traffic_source)
SELECT
	traffic_source,
    total_visits,
    total_buyers,
    sum_revenue,
    ROUND(sum_revenue/total_orders,2) AS order_value,
    ROUND(sum_revenue/total_buyers,2) AS revenue_per_buyer
FROM revenue_funnel;

-- revenue driver
SELECT 
	traffic_source,
	COUNT(DISTINCT (product_id)) AS product, 
    ROUND(SUM(amount),2) AS revenue_by_product
FROM user_events
GROUP BY traffic_source;





