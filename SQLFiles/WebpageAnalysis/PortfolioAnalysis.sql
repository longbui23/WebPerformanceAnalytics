USE mavenfuzzyfactory;

-- gsearch vs bsearch
SELECT 
	MIN(DATE(created_at)) AS week_start_date,
    -- COUNT(DISTINCT website_session_id) AS total_sessions,
    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' THEN website_session_id ELSE NULL END) AS gsearch,
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' THEN website_session_id ELSE NULL END) AS bsearch
    
FROM website_sessions
WHERE created_at > '2012-08-22'
	AND created_at < '2012-11-29'
    AND utm_campaign = 'nonbrand'
    
GROUP BY YEARWEEK(created_at);

-- Comparing Channel Characteristics
SELECT 
	utm_source,
	COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
	COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_sessions.website_session_id ELSE NULL END) AS mobile_session,
	COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_sessions.website_session_id ELSE NULL END)/
	COUNT(DISTINCT website_sessions.website_session_id) AS pct_mobile

FROM website_sessions
WHERE created_at > '2012-08-22'
	AND created_at < '2012-11-29'
	AND utm_campaign = 'nonbrand'
GROUP BY
	utm_source;
         
-- Cross-channel BID Optimization
SELECT 
	website_sessions.device_type,
    website_sessions.utm_source,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id)/ COUNT(DISTINCT website_sessions.website_session_id) AS conv_rt

FROM website_sessions
LEFT JOIN orders USING(website_session_id)
WHERE website_sessions.created_at > '2012-08-22'
	AND website_sessions.created_at < '2012-11-29'
	AND website_sessions.utm_campaign = 'nonbrand'
GROUP BY 
	website_sessions.device_type,
    website_sessions.utm_source;
    
-- Analyzing Channel Portfolio
SELECT 
	MIN(DATE(created_at)) AS week_start_date,
    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND device_type = 'desktop' THEN website_session_id ELSE NULL END) AS gsearch,
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND device_type = 'desktop' THEN website_session_id ELSE NULL END) AS bsearch,
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND device_type = 'desktop' THEN website_session_id ELSE NULL END)/
		COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND device_type = 'desktop' THEN website_session_id ELSE NULL END) AS  b_pct_g_dtop

FROM website_sessions
WHERE website_sessions.created_at > '2012-11-04'
	AND website_sessions.created_at < '2012-12-22'
	AND website_sessions.utm_campaign = 'nonbrand'
GROUP BY
	YEARWEEK(created_at);
    
-- Analyzing Direct Traffic
SELECT
	YEAR(created_at) AS yr,
	MONTH(created_at) AS mo,
    COUNT(DISTINCT CASE WHEN channel_group = "paid_nonbrand" THEN website_session_id ELSE NULL END) AS nonbrand,
    COUNT(DISTINCT CASE WHEN channel_group = "paid_brand" THEN website_session_id ELSE NULL END) AS nonbrand,
    COUNT(DISTINCT CASE WHEN channel_group = "paid_brand" THEN website_session_id ELSE NULL END)/
		COUNT(DISTINCT CASE WHEN channel_group = "paid_nonbrand" THEN website_session_id ELSE NULL END) AS brand_pct_of_nonbrand,
	COUNT(DISTINCT CASE WHEN channel_group = "direct_type_in" THEN website_session_id ELSE NULL END) AS direct,
    COUNT(DISTINCT CASE WHEN channel_group = "direct_type_in" THEN website_session_id ELSE NULL END)/
		COUNT(DISTINCT CASE WHEN channel_group = "paid_nonbrand" THEN website_session_id ELSE NULL END) AS direct_pct_of_nonbrand,
	COUNT(DISTINCT CASE WHEN channel_group = "organic_search" THEN website_session_id ELSE NULL END) AS organic,
	 COUNT(DISTINCT CASE WHEN channel_group = "organic_search" THEN website_session_id ELSE NULL END)/
		COUNT(DISTINCT CASE WHEN channel_group = "paid_nonbrand" THEN website_session_id ELSE NULL END) AS organic_pct_of_nonbrand

FROM (
	SELECT 
		website_session_id, 
        created_at,
		CASE
			WHEN utm_source IS NULL AND http_referer IN ('https://www.gsearch.com', 'https://www.bsearch.com') THEN 'organic_search'
			WHEN utm_campaign = 'nonbrand' THEN 'paid_nonbrand'
			WHEN utm_campaign = 'brand' THEN 'paid_brand'
			WHEN utm_source IS NULL AND http_referer IS NULL THEN 'direct_type_in'
		END AS channel_group
	FROM website_sessions
    WHERE created_at < '2012-12-23'
) AS session_w_channel_group
GROUP BY 1,2;