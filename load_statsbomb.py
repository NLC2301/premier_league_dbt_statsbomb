"""
Download StatsBomb Open Data for one competition-season and load the raw
JSON into DuckDB (schema: raw). dbt then picks these up as sources.

Setup:  pip install duckdb requests
Run:    python load_statsbomb.py

Data: https://github.com/statsbomb/open-data
(StatsBomb's terms ask you to credit them if you publish anything built on it.)
"""
import json
from pathlib import Path

import duckdb
import requests

BASE = "https://raw.githubusercontent.com/statsbomb/open-data/master/data"
RAW_DIR = Path("raw/statsbomb")
DB_PATH = "football.duckdb"

# Change these to any competition/season listed in competitions.json
COMPETITION_NAME = "Premier League"
SEASON_NAME = "2015/2016"


def fetch(path: str):
    """Download a JSON file once and cache it on disk, so reruns are cheap."""
    dest = RAW_DIR / path
    if not dest.exists():
        resp = requests.get(f"{BASE}/{path}", timeout=60)
        resp.raise_for_status()
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(resp.content)
    return json.loads(dest.read_text(encoding="utf-8"))


def main():
    # 1. Find the competition/season IDs
    competitions = fetch("competitions.json")
    match = [
        c for c in competitions
        if c["competition_name"] == COMPETITION_NAME and c["season_name"] == SEASON_NAME
    ]
    if not match:
        available = sorted({(c["competition_name"], c["season_name"]) for c in competitions})
        raise SystemExit(f"Not found. Available options:\n{available}")
    comp_id, season_id = match[0]["competition_id"], match[0]["season_id"]

    # 2. Matches for that season, then events + lineups per match
    matches = fetch(f"matches/{comp_id}/{season_id}.json")
    print(f"{len(matches)} matches found")
    for i, m in enumerate(matches, 1):
        fetch(f"events/{m['match_id']}.json")
        fetch(f"lineups/{m['match_id']}.json")
        if i % 25 == 0:
            print(f"  downloaded {i}/{len(matches)}")

    # 3. Load raw JSON into DuckDB, keeping the nested structure intact
    con = duckdb.connect(DB_PATH)
    con.execute("CREATE SCHEMA IF NOT EXISTS raw")

    con.execute(f"""
        CREATE OR REPLACE TABLE raw.competitions AS
        SELECT * FROM read_json_auto('{RAW_DIR}/competitions.json')
    """)
    con.execute(f"""
        CREATE OR REPLACE TABLE raw.matches AS
        SELECT * FROM read_json_auto('{RAW_DIR}/matches/{comp_id}/{season_id}.json')
    """)
    # match_id comes from the filename (e.g. events/3754058.json)
    con.execute(f"""
        CREATE OR REPLACE TABLE raw.events AS
        SELECT regexp_extract(filename, '([0-9]+)[.]json$', 1)::BIGINT AS match_id, *
        FROM read_json_auto('{RAW_DIR}/events/*.json',
                            union_by_name = true,
                            filename = true,
                            sample_size = -1,
                            maximum_object_size = 33554432)
    """)
    con.execute(f"""
        CREATE OR REPLACE TABLE raw.lineups AS
        SELECT regexp_extract(filename, '([0-9]+)[.]json$', 1)::BIGINT AS match_id, *
        FROM read_json_auto('{RAW_DIR}/lineups/*.json',
                            union_by_name = true,
                            filename = true,
                            sample_size = -1)
    """)

    for t in ("competitions", "matches", "events", "lineups"):
        n = con.execute(f"SELECT count(*) FROM raw.{t}").fetchone()[0]
        print(f"raw.{t}: {n:,} rows")
    con.close()


if __name__ == "__main__":
    main()
