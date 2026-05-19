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
WHERE event_date >= (SELECT DATE_SUB(MAX(event_date), interval 30 day) FROM user_events)
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
WHERE event_date >= (SELECT DATE_SUB(MAX(event_date), interval 30 day) FROM user_events)
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
WHERE event_date >= (SELECT DATE_SUB(MAX(event_date), interval 30 day) FROM user_events)
GROUP BY traffic_source
)
SELECT 
	traffic_source,
	views,
	purchase,
	ROUND(purchase* 100/views,2) AS view_to_purchase_conversion
FROM traffic_funnel;

-- time spent in each funnel
WITH time_spent AS(
	SELECT
		user_id,
		MIN(CASE WHEN event_type = "page_view" THEN event_date END) AS view_time,
        MIN(CASE WHEN event_type = "add_to_cart" THEN event_date END) AS cart_time,
        MIN(CASE WHEN event_type = "purchase" THEN event_date END) AS purchase_time
FROM user_events
GROUP BY user_id
HAVING MIN(CASE WHEN event_type = "purchase" THEN event_date END) IS NOT NULL
)
SELECT 
	COUNT(*) AS converted_users,
    ROUND(AVG(timestampdiff(MINUTE,view_time,cart_time)),2) AS view_cart_time_conversion,
    ROUND(AVG(timestampdiff(MINUTE,cart_time,purchase_time)),2) AS cart_to_purchase_conversion
FROM time_spent;
