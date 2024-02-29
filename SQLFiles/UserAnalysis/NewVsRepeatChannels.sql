-- New vs Repeat Channels
SELECT
	CASE
		WHEN utm_source IS NULL AND http_referer IN ('https://www.gsearch.com', 'https://www.bsearch.com') THEN 'organic_search'
		WHEN utm_campaign = 'nonbrand' THEN 'paid_nonbrand'
		WHEN utm_campaign = 'brand' THEN 'paid_brand'
		WHEN utm_source IS NULL AND http_referer IS NULL THEN 'direct_type_in'
        WHEN utm_source = 'socialbook' THEN 'paid_social'
	END AS channel_group,
    COUNT(CASE WHEN is_repeat_session = 0 THEN website_session_id ELSE NULL END) AS new_sessions,
    COUNT(CASE WHEN is_repeat_session = 1 THEN website_session_id ELSE NULL END) AS repeat_sessions

FROM website_sessions
WHERE created_at < '2014-11-05'
AND created_at >= '2014-01-01'
GROUP BY 1
ORDER BY 3 DESC;

-- CVR and revenue
SELECT
	is_repeat_session,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id)/ COUNT(DISTINCT website_sessions.website_session_id) AS conv_rt,
    SUM(price_usd)/COUNT(DISTINCT website_sessions.website_session_id) AS rev_per_session
    
FROM website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < '2014-11-08'
AND website_sessions.created_at >= '2014-01-01'
GROUP BY 1;