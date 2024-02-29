USE mavenfuzzyfactory;

/*Website-sessions by source*/
SELECT utm_source, utm_campaign, http_referer, COUNT(DISTINCT website_session_id) AS number_session
FROM website_sessions
WHERE created_at <= "2012-04-12"
GROUP BY 1,2,3
ORDER BY 4 DESC;

/*Conversion rate*/
SELECT COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
		COUNT(DISTINCT orders.order_id) AS orders,
        COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id) AS session_to_order_conv_rt
FROM website_sessions
LEFT JOIN orders USING(website_session_id)
WHERE website_sessions.created_at <= "2012-04-12"
AND website_sessions.utm_source = "gsearch"
AND website_sessions.utm_campaign = "nonbrand";

/*Trending Pages*/
SELECT MIN(DATE(created_at)) AS week_started_at,
		COUNT(DISTINCT website_session_id) AS sessions
FROM website_sessions
WHERE created_at <= "2012-05-15"
AND utm_source = "gsearch"
AND utm_campaign = "nonbrand"
GROUP BY YEAR(created_at), WEEK(created_at);

/*BID Optimization*/
SELECT website_sessions.device_type,
		COUNT(DISTINCT orders.order_id) AS orders,
        COUNT(DISTINCT orders.order_id)/ COUNT(DISTINCT website_sessions.website_session_id) AS conv_rt
FROM website_sessions
LEFT JOIN orders USING(website_session_id)
WHERE website_sessions.created_at <= '2012-05-11'
GROUP BY 1;

/*A/B Testing after Increasing BID*/
SELECT MIN(DATE(created_at)) AS week_started_at,
		COUNT(CASE WHEN device_type = "desktop" THEN website_session_id ELSE NULL END) AS desktop_session,
		COUNT(CASE WHEN device_type = "mobile" THEN website_session_id ELSE NULL END) AS mobile_session
FROM website_sessions
WHERE created_at >= "2012-04-15"
AND utm_source = "gsearch"
AND utm_campaign = "nonbrand"
GROUP BY YEAR(created_at), WEEK(created_at);
