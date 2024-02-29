USE mavenfuzzyfactory;

-- Seasonality Analysis
SELECT
	YEAR(website_sessions.created_at) AS yr,
    MONTH(website_sessions.created_at) AS mo,
    MIN(DATE(website_sessions.created_at)) AS week_start,
	COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders
    
FROM website_sessions
LEFT JOIN orders
	ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < '2013-01-01'
GROUP BY 1,2;

-- Analyzing Bussiness Pattern
SELECT
	hr,
    ROUND(AVG(website_sessions),1) AS ave_sesssions,
    AVG(CASE WHEN wkday = 0 THEN website_sessions ELSE NULL END) AS mon,
    AVG(CASE WHEN wkday = 1 THEN website_sessions ELSE NULL END) AS tues
FROM (
	SELECT
		DATE(created_at) AS created_date,
		WEEKDAY(created_at) AS wkday,
		HOUR(created_at) AS hr,
		COUNT(DISTINCT website_session_id) AS website_sessions
	FROM website_sessions
    WHERE created_at BETWEEN '2012-09-15' AND '2012-11-15'
    GROUP BY 1,2,3
) AS daily_hourlu_sessions
GROUP BY 1
ORDER BY 1;
	