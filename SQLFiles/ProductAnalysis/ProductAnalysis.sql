/* sessions_w_counts_lander_and_created_at */
SELECT YEAR(created_at) AS yr, 
		MONTH(created_at) AS mo,
        COUNT(DISTINCT order_id) AS number_of_states,
        SUM(price_usd) AS total_revenue,
        SUM(cogs_usd) AS total_margin
FROM orders
WHERE created_at < "2013-01-04"
GROUP by 1,2;

/*Product Launches*/
SELECT YEAR(website_sessions.created_at) AS yr, 
		MONTH(website_sessions.created_at) AS mo,
        COUNT(website_sessions.website_session_id) AS sessions,
        COUNT(DISTINCT orders.order_id) AS orders,
		COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate,
        SUM(orders.price_usd) / COUNT(DISTINCT website_sessions.website_session_id) AS revenue_per_session
FROM website_sessions 
LEFT JOIN orders USING(website_session_id)
WHERE website_sessions.created_at BETWEEN "2012-04-01" AND "2013-04-01"
GROUP BY 1,2;

/*Product-Level Website Pathing*/
-- pageview_url
CREATE TEMPORARY TABLE product_pageviews
SELECT website_session_id, website_pageview_id, created_at,
	CASE 
		WHEN created_at < "2013-01-06"  THEN "A. Pre_Product_2" 
		WHEN created_at >= "2013-01-05" THEN "B.Post_Product_2" 
        ELSE "Null"
	END AS time_period
FROM website_pageviews
WHERE created_at > "2012-10-06" AND 
created_at < "2013-04-06"
AND pageview_url = "/products";

-- Website_pageview_id after accessing /products
CREATE TEMPORARY TABLE session_w_next_pageview_id
SELECT product_pageviews.time_period,
	product_pageviews.website_session_id,
    MIN(website_pageviews.website_pageview_id) AS min_next_pageview_id
FROM product_pageviews
LEFT JOIN website_pageviews
	ON website_pageviews.website_session_id = product_pageviews.website_session_id
	AND website_pageviews.website_pageview_id > product_pageviews.website_pageview_id
GROUP BY 1,2;

CREATE TEMPORARY TABLE sessions_w_next_pageview_url
SELECT session_w_next_pageview_id.time_period, session_w_next_pageview_id.website_session_id, website_pageviews.pageview_url
FROM session_w_next_pageview_id
LEFT JOIN website_pageviews
	ON website_pageviews.website_pageview_id =session_w_next_pageview_id.min_next_pageview_id;
    
-- Result
SELECT time_period,
	COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN pageview_url IS NOT NULL THEN website_session_id ELSE NULL END) AS w_next_pg,
    COUNT(DISTINCT CASE WHEN pageview_url IS NOT NULL THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS pct_w_next_pg,
    COUNT(DISTINCT CASE WHEN pageview_url = "/the-original-mr-fuzzy" THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
    COUNT(DISTINCT CASE WHEN pageview_url = "/the-original-mr-fuzzy" THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS pct_to_mrfuzzy,
    COUNT(DISTINCT CASE WHEN pageview_url = "/the-forever-love-bear" THEN website_session_id ELSE NULL END) AS to_lovebear,
    COUNT(DISTINCT CASE WHEN pageview_url = "/the-forever-love-bear" THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS pct_to_lovebear
FROM sessions_w_next_pageview_url
GROUP BY 1;