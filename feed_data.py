"""
Step 2: Feed CSV data into the SQLite database.
Reads the Kaggle CSV and populates all normalized relations.
"""

import sqlite3
import csv
import os

CSV_PATH  = os.path.join(os.path.dirname(__file__), "social_media_mental_health 2.csv")
DB_PATH   = os.path.join(os.path.dirname(__file__), "mental_health.db")
SQL_PATH  = os.path.join(os.path.dirname(__file__), "schema.sql")


def get_or_insert(cursor, table, name_col, id_col, value):
    cursor.execute(f"SELECT {id_col} FROM {table} WHERE {name_col} = ?", (value,))
    row = cursor.fetchone()
    if row:
        return row[0]
    cursor.execute(f"INSERT INTO {table} ({name_col}) VALUES (?)", (value,))
    return cursor.lastrowid


def main():
    # Create / reset database
    if os.path.exists(DB_PATH):
        os.remove(DB_PATH)

    conn = sqlite3.connect(DB_PATH)
    conn.execute("PRAGMA foreign_keys = ON")
    cur = conn.cursor()

    # Apply schema
    with open(SQL_PATH, "r") as f:
        conn.executescript(f.read())

    inserted = 0
    skipped  = 0

    with open(CSV_PATH, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            try:
                archetype_id    = get_or_insert(cur, "archetypes",    "archetype_name",    "archetype_id",    row["User_Archetype"])
                platform_id     = get_or_insert(cur, "platforms",     "platform_name",     "platform_id",     row["Primary_Platform"])
                content_type_id = get_or_insert(cur, "content_types", "content_type_name", "content_type_id", row["Dominant_Content_Type"])

                cur.execute(
                    "INSERT OR IGNORE INTO users (user_id, age, gender, archetype_id, platform_id) VALUES (?, ?, ?, ?, ?)",
                    (row["User_ID"], int(row["Age"]), row["Gender"], archetype_id, platform_id),
                )

                cur.execute(
                    """INSERT OR IGNORE INTO usage_behavior
                       (user_id, daily_screen_time_hours, content_type_id, activity_type,
                        late_night_usage, social_comparison_trigger, sleep_duration_hours)
                       VALUES (?, ?, ?, ?, ?, ?, ?)""",
                    (
                        row["User_ID"],
                        float(row["Daily_Screen_Time_Hours"]),
                        content_type_id,
                        row["Activity_Type"],
                        int(row["Late_Night_Usage"]),
                        int(row["Social_Comparison_Trigger"]),
                        float(row["Sleep_Duration_Hours"]),
                    ),
                )

                cur.execute(
                    "INSERT OR IGNORE INTO mental_health_scores (user_id, gad7_score, phq9_score) VALUES (?, ?, ?)",
                    (row["User_ID"], int(row["GAD_7_Score"]), int(row["PHQ_9_Score"])),
                )

                inserted += 1
            except (ValueError, KeyError) as e:
                skipped += 1
                print(f"  Skipped row {row.get('User_ID', '?')}: {e}")

    conn.commit()
    conn.close()

    print(f"\nDone. Inserted: {inserted} users | Skipped: {skipped}")
    print(f"Database saved to: {DB_PATH}")


if __name__ == "__main__":
    main()
