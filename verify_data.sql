-- Step 3: Verify data loaded correctly with SQL SELECT queries

-- 1. Row counts per table
SELECT 'archetypes'         AS tbl, COUNT(*) AS rows FROM archetypes
UNION ALL
SELECT 'platforms',           COUNT(*) FROM platforms
UNION ALL
SELECT 'content_types',       COUNT(*) FROM content_types
UNION ALL
SELECT 'users',               COUNT(*) FROM users
UNION ALL
SELECT 'usage_behavior',      COUNT(*) FROM usage_behavior
UNION ALL
SELECT 'mental_health_scores',COUNT(*) FROM mental_health_scores;


-- 2. Sample: first 10 users with full details (denormalized view)
SELECT
    u.user_id,
    u.age,
    u.gender,
    a.archetype_name,
    p.platform_name,
    ub.daily_screen_time_hours,
    ct.content_type_name,
    ub.activity_type,
    ub.late_night_usage,
    ub.social_comparison_trigger,
    ub.sleep_duration_hours,
    mh.gad7_score,
    g.severity_label  AS gad7_severity,
    mh.phq9_score,
    ph.severity_label AS phq9_severity
FROM users u
JOIN archetypes      a  ON u.archetype_id         = a.archetype_id
JOIN platforms       p  ON u.platform_id           = p.platform_id
JOIN usage_behavior  ub ON u.user_id               = ub.user_id
JOIN content_types   ct ON ub.content_type_id      = ct.content_type_id
JOIN mental_health_scores mh ON u.user_id          = mh.user_id
JOIN gad7_severity_ranges g  ON mh.gad7_score BETWEEN g.min_score AND g.max_score
JOIN phq9_severity_ranges ph ON mh.phq9_score BETWEEN ph.min_score AND ph.max_score
LIMIT 10;


-- 3. Check referential integrity — should return 0
SELECT COUNT(*) AS orphan_usage   FROM usage_behavior       WHERE user_id NOT IN (SELECT user_id FROM users);
SELECT COUNT(*) AS orphan_scores  FROM mental_health_scores WHERE user_id NOT IN (SELECT user_id FROM users);


-- 4. Distinct platforms and user count per platform
SELECT p.platform_name, COUNT(*) AS user_count
FROM users u
JOIN platforms p ON u.platform_id = p.platform_id
GROUP BY p.platform_name
ORDER BY user_count DESC;


-- 5. Distribution of GAD-7 severity
SELECT g.severity_label, COUNT(*) AS count,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM mental_health_scores), 2) AS pct
FROM mental_health_scores mh
JOIN gad7_severity_ranges g ON mh.gad7_score BETWEEN g.min_score AND g.max_score
GROUP BY g.severity_label
ORDER BY g.min_score;


-- 6. Distribution of PHQ-9 severity
SELECT ph.severity_label, COUNT(*) AS count,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM mental_health_scores), 2) AS pct
FROM mental_health_scores mh
JOIN phq9_severity_ranges ph ON mh.phq9_score BETWEEN ph.min_score AND ph.max_score
GROUP BY ph.severity_label
ORDER BY ph.min_score;


-- 7. Average screen time and sleep by archetype
SELECT a.archetype_name,
       ROUND(AVG(ub.daily_screen_time_hours), 2) AS avg_screen_time,
       ROUND(AVG(ub.sleep_duration_hours), 2)    AS avg_sleep,
       ROUND(AVG(mh.gad7_score), 2)              AS avg_gad7,
       ROUND(AVG(mh.phq9_score), 2)              AS avg_phq9
FROM users u
JOIN archetypes           a  ON u.archetype_id    = a.archetype_id
JOIN usage_behavior       ub ON u.user_id          = ub.user_id
JOIN mental_health_scores mh ON u.user_id          = mh.user_id
GROUP BY a.archetype_name
ORDER BY avg_gad7 DESC;


-- 8. Late-night usage vs. average sleep duration
SELECT ub.late_night_usage,
       COUNT(*)                                AS users,
       ROUND(AVG(ub.sleep_duration_hours), 2) AS avg_sleep_hrs,
       ROUND(AVG(mh.gad7_score), 2)           AS avg_gad7,
       ROUND(AVG(mh.phq9_score), 2)           AS avg_phq9
FROM usage_behavior       ub
JOIN mental_health_scores mh ON ub.user_id = mh.user_id
GROUP BY ub.late_night_usage;
