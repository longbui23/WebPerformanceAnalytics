/*Most Viewed Webpages*/
SELECT pageview_url, COUNT(DISTINCT website_pageview_id) AS pvs
FROM website_pageviews
WHERE created_at < "2012-06-09"
GROUP BY 1
ORDER BY 2 DESC;

/*Total session with first webpage*/
USE mavenfuzzyfactory;

#DROP TABLE first_pv_per_session;
CREATE TEMPORARY TABLE first_pv_per_session
SELECT website_session_id, MIN(website_pageview_id) AS first_pv
FROM website_pageviews
WHERE created_at < '2012-06-12'
GROUP BY 1;

SELECT website_pageviews.pageview_url AS landing_page_url,
	COUNT(DISTINCT first_pv_per_session.website_session_id) AS sessions_hitting_page
FROM website_pageviews
LEFT JOIN first_pv_per_session ON website_pageviews.website_pageview_id = first_pv_per_session.first_pv
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

/* Landing page analysis*/
USE mavenfuzzyfactory;
-- first_pageviews
#DROP TABLE first_pageviews;
CREATE TEMPORARY TABLE first_pageviews
SELECT
	website_session_id,
    MIN(website_pageview_id) AS min_pageview_id
FROM website_pageviews
WHERE created_at < '2012-06-14'
GROUP BY 1;

-- home landing page
#DROP TABLE session_w_home_landing_page;
CREATE TEMPORARY TABLE session_w_home_landing_page
SELECT 
	first_pageviews.website_session_id,
	website_pageviews.pageview_url AS landing_page
FROM first_pageviews
LEFT JOIN website_pageviews
ON website_pageviews.website_pageview_id = first_pageviews.min_pageview_id
WHERE website_pageviews.pageview_url = '/home';

-- bounced_sessions
CREATE TEMPORARY TABLE bounced_sessions
SELECT
	session_w_home_landing_page.website_session_id,
    session_w_home_landing_page.landing_page,
    COUNT(website_pageviews.website_pageview_id) AS count_of_pages_viewed
FROM session_w_home_landing_page
LEFT JOIN website_pageviews
ON website_pageviews.website_session_id = session_w_home_landing_page.website_session_id
GROUP BY 1,2
HAVING COUNT(website_pageviews.website_pageview_id) = 1;

-- session_w_home_landing_page
SELECT session_w_home_landing_page.website_session_id,
    bounced_sessions.website_session_id AS bounced_website_session_id
FROM session_w_home_landing_page
LEFT JOIN bounced_sessions
ON session_w_home_landing_page.website_session_id = bounced_sessions.website_session_id
ORDER BY session_w_home_landing_page.website_session_id;

-- Result
SELECT COUNT(DISTINCT session_w_home_landing_page.website_session_id) AS sessions,
		COUNT(DISTINCT bounced_sessions.website_session_id) AS bounced_sessions,
        COUNT(DISTINCT bounced_sessions.website_session_id) / COUNT(DISTINCT session_w_home_landing_page.website_session_id) AS bounced_rate
FROM session_w_home_landing_page
LEFT JOIN bounced_sessions
USING(website_session_id);

/* A/B Testing */
-- lander-1 being added
SELECT MIN(created_at) AS first_created_at,
	MIN(website_pageview_id) AS first_pageview_id
FROM website_pageviews
WHERE pageview_url = '/lander-1'
AND created_at IS NOT NULL;

-- web_pageview_id during '/lander-1' being added
CREATE TEMPORARY TABLE first_test_pageviews
SELECT
	website_pageviews.website_session_id,
    MIN(website_pageviews.website_pageview_id) AS min_pageview_id
FROM website_pageviews
INNER JOIN website_sessions
ON website_sessions.website_session_id = website_pageviews.website_session_id
AND website_sessions.created_at < '2012-07-28'
		and website_pageviews.website_pageview_id > 23504
        and utm_source = 'gsearch'
		and utm_campaign = 'nonbrand'
group by
	website_pageviews.website_session_id;

-- map  web_pageview_id and landing page (/home, /lander-1)
CREATE TEMPORARY TABLE nonbrand_test_session_w_landing_page
SELECT
	first_test_pageviews.website_session_id,
    website_pageviews.pageview_url AS landing_page
FROM first_test_pageviews
LEFT JOIN website_pageviews
ON website_pageviews.website_pageview_id = first_test_pageviews.min_pageview_id
WHERE website_pageviews.pageview_url in ('/home', '/lander-1');

-- các website_session bị thoát phiên
CREATE TEMPORARY TABLE nonbrand_test_bounced_sessions
SELECT nonbrand_test_session_w_landing_page.website_session_id,
	 nonbrand_test_session_w_landing_page.landing_page,
    COUNT(website_pageviews.website_pageview_id) AS counts_of_page_view
FROM  nonbrand_test_session_w_landing_page
LEFT JOIN website_pageviews USING(website_session_id)
GROUP BY 1,2
HAVING COUNT(website_pageviews.website_pageview_id) = 1;

--  bounced session with '/home', '/lander-1' 
SELECT nonbrand_test_session_w_landing_page.landing_page, 
	COUNT(DISTINCT nonbrand_test_session_w_landing_page.website_session_id) AS sessions,
	COUNT(DISTINCT nonbrand_test_bounced_sessions.website_session_id) AS bounced_sessions,
    COUNT(DISTINCT nonbrand_test_bounced_sessions.website_session_id) / 
    COUNT(DISTINCT nonbrand_test_session_w_landing_page.website_session_id) AS bounced_rate
FROM nonbrand_test_session_w_landing_page
LEFT JOIN  nonbrand_test_bounced_sessions USING(website_session_id)
GROUP BY landing_page;

/* Numbers of sessions bounce to home and lander */
CREATE TEMPORARY TABLE sessions_w_min_pv_id_and_view_count
SELECT
	website_sessions.website_session_id,
    MIN(website_pageviews.website_pageview_id) AS first_pageview_id,
    COUNT(website_pageviews.website_pageview_id) AS count_pageviews
FROM website_sessions
LEFT JOIN website_pageviews
ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE website_sessions.created_at > '2012-06-01'
AND website_sessions.created_at < '2012-08-31'
AND website_sessions.utm_source = 'gsearch'
AND website_sessions.utm_campaign = 'nonbrand'
GROUP BY website_sessions.website_session_id;

-- count_pageviews
CREATE TEMPORARY TABLE sessions_w_counts_lander_and_created_at
SELECT
	sessions_w_min_pv_id_and_view_count.website_session_id,
    sessions_w_min_pv_id_and_view_count.first_pageview_id,
    sessions_w_min_pv_id_and_view_count.count_pageviews,
    website_pageviews.pageview_url as landing_page,
    website_pageviews.created_at as session_created_at
FROM sessions_w_min_pv_id_and_view_count
LEFT JOIN website_pageviews
ON sessions_w_min_pv_id_and_view_count.first_pageview_id = website_pageviews.website_pageview_id;

-- bounced website session by page 
SELECT MIN(DATE(website_sessions.created_at)) AS week_start_date,
	COUNT(DISTINCT website_sessions.website_session_id) AS total_sessions,
    COUNT(CASE WHEN sessions_w_counts_lander_and_created_at.count_pageviews = 1 THEN first_pageview_id END)/ 
    COUNT(DISTINCT website_sessions.website_session_id) AS bounce_rt,
	SUM(CASE WHEN sessions_w_counts_lander_and_created_at.landing_page = '/home' THEN 1 ELSE 0 END) AS home_sessions,
	SUM(CASE WHEN sessions_w_counts_lander_and_created_at.landing_page = '/lander-1' THEN 1 ELSE 0 END) AS lander_sessions
FROM website_sessions
	LEFT JOIN sessions_w_counts_lander_and_created_at USING(website_session_id)
WHERE website_sessions.created_at > '2012-06-01' AND website_sessions.created_at < '2012-08-31'
	AND website_sessions.utm_source = 'gsearch' AND website_sessions.utm_campaign = 'nonbrand'
GROUP BY YEAR(website_sessions.created_at),
		WEEK(website_sessions.created_at);
        
	
