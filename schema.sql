-- Step 1: Database Schema in 3NF (Third Normal Form)
-- Social Media & Mental Health Dataset

PRAGMA foreign_keys = ON;

-- Dimension: User archetypes
CREATE TABLE IF NOT EXISTS archetypes (
    archetype_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    archetype_name TEXT    NOT NULL UNIQUE
);

-- Dimension: Social media platforms
CREATE TABLE IF NOT EXISTS platforms (
    platform_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    platform_name TEXT    NOT NULL UNIQUE
);

-- Dimension: Dominant content types
CREATE TABLE IF NOT EXISTS content_types (
    content_type_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    content_type_name TEXT    NOT NULL UNIQUE
);

-- Dimension: GAD-7 severity score ranges (removes transitive dependency)
CREATE TABLE IF NOT EXISTS gad7_severity_ranges (
    severity_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    min_score      INTEGER NOT NULL,
    max_score      INTEGER NOT NULL,
    severity_label TEXT    NOT NULL UNIQUE
);

-- Dimension: PHQ-9 severity score ranges (removes transitive dependency)
CREATE TABLE IF NOT EXISTS phq9_severity_ranges (
    severity_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    min_score      INTEGER NOT NULL,
    max_score      INTEGER NOT NULL,
    severity_label TEXT    NOT NULL UNIQUE
);

-- Core: Users (demographic data)
CREATE TABLE IF NOT EXISTS users (
    user_id      TEXT    PRIMARY KEY,
    age          INTEGER NOT NULL CHECK (age >= 0 AND age <= 120),
    gender       TEXT    NOT NULL,
    archetype_id INTEGER NOT NULL REFERENCES archetypes(archetype_id),
    platform_id  INTEGER NOT NULL REFERENCES platforms(platform_id)
);

-- Fact: Usage behavior (one record per user)
CREATE TABLE IF NOT EXISTS usage_behavior (
    user_id                   TEXT    PRIMARY KEY REFERENCES users(user_id),
    daily_screen_time_hours   REAL    NOT NULL CHECK (daily_screen_time_hours >= 0),
    content_type_id           INTEGER NOT NULL REFERENCES content_types(content_type_id),
    activity_type             TEXT    NOT NULL CHECK (activity_type IN ('Active', 'Passive')),
    late_night_usage          INTEGER NOT NULL CHECK (late_night_usage IN (0, 1)),
    social_comparison_trigger INTEGER NOT NULL CHECK (social_comparison_trigger IN (0, 1)),
    sleep_duration_hours      REAL    NOT NULL CHECK (sleep_duration_hours >= 0)
);

-- Fact: Mental health assessment scores
CREATE TABLE IF NOT EXISTS mental_health_scores (
    user_id     TEXT    PRIMARY KEY REFERENCES users(user_id),
    gad7_score  INTEGER NOT NULL CHECK (gad7_score >= 0 AND gad7_score <= 21),
    phq9_score  INTEGER NOT NULL CHECK (phq9_score >= 0 AND phq9_score <= 27)
);

-- Seed GAD-7 severity ranges
INSERT OR IGNORE INTO gad7_severity_ranges (min_score, max_score, severity_label) VALUES
    (0,  4,  'Minimal'),
    (5,  9,  'Mild'),
    (10, 14, 'Moderate'),
    (15, 21, 'Severe');

-- Seed PHQ-9 severity ranges
INSERT OR IGNORE INTO phq9_severity_ranges (min_score, max_score, severity_label) VALUES
    (0,  4,  'None-Minimal'),
    (5,  9,  'Mild'),
    (10, 14, 'Moderate'),
    (15, 19, 'Moderately Severe'),
    (20, 27, 'Severe');
