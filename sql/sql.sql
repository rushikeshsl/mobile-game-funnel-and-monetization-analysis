-- user_id,
--	event,
--	timestamp,
--	country,
--	channel,
--	device_type,
--	age_group,
--	level_number,
--	session_count,
--	session_duration_sec,
--	days_since_install,
--	ad_type,
--	ads_shown_count,
--	is_churned

-- Importing dataset

CREATE TABLE funnel_data AS
SELECT *
FROM read_csv_auto("C:\Users\Rushikesh\Downloads\gaming_funnel_dataset.csv")
;


-- Descriptive Analysis

SELECT *
FROM funnel_data;

SELECT DISTINCT event
FROM funnel_data;

SELECT DISTINCT country
FROM funnel_data;

SELECT DISTINCT channel
FROM funnel_data;

SELECT DISTINCT device_type
FROM funnel_data;


-- Unique Players Per Stage

SELECT 
	event, count(*)
FROM funnel_data 
GROUP BY event
ORDER BY 2 desc;


-- Activation Funnel

WITH funnel_counts AS (
    SELECT 
        event,
        COUNT(DISTINCT user_id) AS users
    FROM funnel_data
    WHERE event IN (
        'app_install',
        'app_open',
        'signup_complete',
        'tutorial_complete',
        'level_complete'
    )
    GROUP BY event
),
ordered_funnel AS (
    SELECT
        CASE
            WHEN event = 'app_install' THEN 1
            WHEN event = 'app_open' THEN 2
            WHEN event = 'signup_complete' THEN 3
            WHEN event = 'tutorial_complete' THEN 4
            WHEN event = 'level_complete' THEN 5
        END AS stage_order,
        event,
        users
    FROM funnel_counts
),
install_base AS (
    SELECT users AS total_installs
    FROM ordered_funnel
    WHERE stage_order = 1
)
SELECT
    f.stage_order,
    f.event,
    f.users,
    ROUND((f.users * 100.0 / i.total_installs), 2) AS conversion_rate_pct,
    ROUND((100 - (f.users * 100.0 / i.total_installs)), 2) AS drop_off_rate_pct
FROM ordered_funnel f
CROSS JOIN install_base i
ORDER BY f.stage_order;


-- Monetization Funnel

WITH funnel_counts AS (
    SELECT 
        event,
        COUNT(DISTINCT user_id) AS users
    FROM funnel_data
    WHERE event IN (
        'app_install',
        'level_complete',
        'ad_impression',
        'ad_reward_claimed'
    )
    GROUP BY event
),
ordered_funnel AS (
    SELECT
        CASE
            WHEN event = 'app_install' THEN 1
            WHEN event = 'level_complete' THEN 2
            WHEN event = 'ad_impression' THEN 3
            WHEN event = 'ad_reward_claimed' THEN 4
        END AS stage_order,
        event,
        users
    FROM funnel_counts
),
install_base AS (
    SELECT users AS total_installs
    FROM ordered_funnel
    WHERE stage_order = 1
)
SELECT
    f.stage_order,
    f.event,
    f.users,
    ROUND((f.users * 100.0 / i.total_installs), 2) AS conversion_rate_pct,
    ROUND((100 - (f.users * 100.0 / i.total_installs)), 2) AS drop_off_rate_pct
FROM ordered_funnel f
CROSS JOIN install_base i
ORDER BY f.stage_order;


-- Segmented Funnel Analysis

WITH funnel_events AS (
    SELECT
        user_id,
        event,
        device_type,
        country,
        channel,
     FROM funnel_data    
),
funnel_counts AS (
    SELECT
        device_type,
        country,
        channel,
        event,
        COUNT(DISTINCT user_id) AS users,
        CASE
            WHEN event = 'app_install' THEN 1
            WHEN event = 'app_open' THEN 2
            WHEN event = 'signup_complete' THEN 3
            WHEN event = 'tutorial_complete' THEN 4
            WHEN event = 'level_complete' THEN 5
            WHEN event = 'ad_impression' THEN 6
            WHEN event = 'ad_reward_claimed' THEN 7
        END AS stage_order
    FROM funnel_events
    GROUP BY
        device_type,
        country,
        channel,
        event
),
install_base AS (
    SELECT
        device_type,
        country,
        channel,
        users AS total_installs
    FROM funnel_counts
    WHERE event = 'app_install'
)
SELECT
    f.device_type,
    f.country,
    f.channel,
    f.stage_order,
    f.event,
    f.users,
    ROUND(
        (f.users * 100.0 / i.total_installs),
        2
    ) AS conversion_rate_pct,
    ROUND(
        (100 - (f.users * 100.0 / i.total_installs)),
        2
    ) AS drop_off_rate_pct
FROM funnel_counts f
JOIN install_base i
    ON f.device_type = i.device_type
   AND f.country = i.country
   AND f.channel = i.channel  
ORDER BY
    f.device_type,
    f.country,
    f.channel,    
    f.stage_order;




