USE mavenfuzzyfactory;

-- Identifying Repeating Session
CREATE TEMPORARY TABLE sessions_w_repeats
SELECT
	 new_sessions.user_id,
     new_sessions.website_session_id AS new_session_id,
     website_sessions.website_session_id AS repeat_session_id
FROM (
	SELECT
		user_id,
        website_session_id
	FROM website_sessions
    WHERE created_at < '2014-11-01'
    AND created_at >= '2014-01-01'
    AND is_repeat_session = 0
) AS new_sessions
LEFT JOIN website_sessions
ON website_sessions.user_id = new_sessions.user_id
AND website_sessions.is_repeat_session = 1
AND website_sessions.website_session_id > new_sessions.website_session_id
AND website_sessions.created_at < '2014-11-01'
AND website_sessions.created_at >= '2014-01-01';


SELECT
	repeat_sessions,
    COUNT(DISTINCT user_id) AS users
FROM (
	SELECT
		user_id,
		COUNT(DISTINCT new_session_id) AS new_sessions,
		COUNT(DISTINCT repeat_session_id) AS repeat_sessions
	FROM sessions_w_repeats
	GROUP BY 1
	ORDER BY 3 DESC
	) AS user_level

GROUP BY 1;

-- Analyzing Repeat Channel
CREATE TEMPORARY TABLE sessions_w_repeats_for_time_diff
SELECT
	 new_sessions.user_id,
     new_sessions.website_session_id AS new_session_id,
     website_sessions.website_session_id AS repeat_session_id,
     website_sessions.created_at AS repeat_session_created_at
FROM (
	SELECT
		user_id,
        website_session_id,
        created_at
	FROM website_sessions
    WHERE created_at < '2014-11-01'
    AND created_at >= '2014-01-01'
    AND is_repeat_session = 0
) AS new_sessions
LEFT JOIN website_sessions
ON website_sessions.user_id = new_sessions.user_id
AND website_sessions.is_repeat_session = 1
AND website_sessions.website_session_id > new_sessions.website_session_id
AND website_sessions.created_at < '2014-11-01'
AND website_sessions.created_at >= '2014-01-01';

-- time differences
CREATE TEMPORARY TABLE users_first_to_second
SELECT
	user_id,
    DATEDIFF(second_session_created_at, new_session_created_at) AS day_first_to_second_session
FROM (
	SELECT
		user_id,
        new_session_id,
        new_session_created_at,
        AVG(days_first_to_second_session) AS avg_days_fist_to_second
        MIN(repeat_session_id) AS second_session_id,
        MIN(repeat_session_created_at) AS second_session_created_at
	FROM sessions_w_repeats_for_time_diff
    WHERE repeat_session_id IS NOT NULL
    GROUP BY 1,2,3
) AS first_second;

SELECT
	AVG(days_first_to_second_session) AS avg_days_fist_to_second,
    MIN(days_first_to_second_session) AS min_days_fist_to_second,
    MAX(days_first_to_second_session) AS max_days_fist_to_second
FROM user_first_to_second;
    
