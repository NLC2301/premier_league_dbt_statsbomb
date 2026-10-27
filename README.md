# Football Analytics with dbt and DuckDB

An analytics engineering project that turns raw [StatsBomb Open Data](https://github.com/statsbomb/open-data) (Premier League 2015/16, including 1.3 million event-level records) into tested, documented tables ready for analysis.

I built it to practise the full dbt workflow on realistic, messy data: nested JSON in, a clean dimensional model out, with tests and documentation along the way into a dahsboard from which valuable insights can be drawn.

Stack: Python, DuckDB, dbt Core (dbt-duckdb), dbt_utils, Power BI



## What's in the data

StatsBomb publishes match, lineup and event data as nested JSON files. For one season that's:

| Source table | Rows | Grain |

| `matches` | 380 | one row per match |
| `lineups` | 760 | one row per team per match (players stored as a nested list) |
| `events` | ~1.3 million | one row per on-pitch event (pass, shot, carry, etc.) |
| `competitions` | 80 | one row per competition-season available in the open data |

The nested structure is the main modelling challenge: team, player and event details are structs, and each player's positions and cards are lists inside lists.

## How the project is organised

```
Football/
├── load_statsbomb.py          # downloads the JSON and loads it into DuckDB (schema: raw)
└── football_analytics/        # the dbt project
    ├── models/
    │   ├── staging/           # one model per source table, light cleaning only
    │   │   ├── sources.yml
    │   │   ├── _staging.yml
    │   │   ├── stg_statsbomb__matches.sql
    │   │   ├── stg_statsbomb__events.sql
    │   │   └── stg_statsbomb__lineups.sql
    │   └── marts/             # models built for analysis
    │       ├── _marts.yml
    │       ├── dim_teams.sql
    │       ├── fct_matches.sql
    │       └── fct_shots.sql
    ├── tests/                 # custom (singular) tests
    └── packages.yml           # dbt_utils
```

### Layers

**Raw (loaded by Python).** `load_statsbomb.py` downloads the JSON for a chosen competition and season, caches it locally, and loads it into DuckDB with nested structures left intact. Transformation is left to dbt.

**Staging.** Each staging model maps to one source table. It unpacks structs into flat, consistently named columns, fixes types and makes boolean flags explicit. In `stg_statsbomb__lineups`, the nested player list is unnested to one row per player per match. Event-specific structs (pass, shot, carry and so on) are deliberately left nested, because they only apply to one event type each and are unpacked in purpose-built marts.

**Marts.**

| Model | Grain | Description |

| `dim_teams` | one row per team | Distinct teams, taken from home and away sides of every match |
| `fct_matches` | one row per match | Result, winner, total goals and points awarded to each side |
| `fct_shots` | one row per shot | Shot location, xG, outcome, body part, technique and goal/penalty flags |

## Testing and documentation

Every model has tests, run with `dbt test` (or as part of `dbt build`):

- **Keys:** `unique` and `not_null` on each model's primary key
- **Referential integrity:** every event's `match_id` exists in matches, and every shot's `team_id` exists in `dim_teams`
- **Composite key:** `match_id` + `player_id` is unique in lineups (`dbt_utils.unique_combination_of_columns`)
- **Valid values:** `result` is one of `home_win`, `away_win`, `draw`; points are 0, 1 or 3; xG is between 0 and 1
- **Custom test:** `home_points + away_points` is always 2 or 3, which catches inconsistencies no single-column test would

Model and column descriptions live in the YAML files and feed the generated docs site (`dbt docs generate` then `dbt docs serve`).

## How to run it

Prerequisites: Python 3.10+ and Git. This was developed on Python 3.14.

```bash
# 1. Clone and set up an environment
git clone https://github.com/<your-username>/<your-repo>.git
cd <your-repo>
python -m venv .venv
.venv\Scripts\activate          # macOS/Linux: source .venv/bin/activate
pip install duckdb requests dbt-duckdb

# 2. Download the data and load it into DuckDB (takes a few minutes the first time)
python load_statsbomb.py

# 3. Run dbt from the project folder
cd football_analytics
dbt deps
dbt build
```

`dbt` needs a profile in `~/.dbt/profiles.yml` (on Windows: `C:\Users\<you>\.dbt\profiles.yml`):

```yaml
football_analytics:
  target: dev
  outputs:
    dev:
      type: duckdb
      path: ../football.duckdb
      threads: 4
```

The path is relative to the `football_analytics` folder, so it points at the database the loader creates one level up.

To browse the documentation and lineage graph:

```bash
dbt docs generate
dbt docs serve
```

To load a different competition or season, change `COMPETITION_NAME` and `SEASON_NAME` at the top of `load_statsbomb.py`. If the name isn't found, the script prints the available options.

## Example findings

> TODO: replace this section with your own results before publishing. A few ideas, with the queries that would produce them:

- **Total xG vs actual goals.** `select count(*), sum(is_goal::int), round(sum(xg), 1) from fct_shots` shows how closely expected goals tracked reality across the season.
- **Over- and under-performers.** Group `fct_shots` by player and compare `sum(xg)` with the number of goals, excluding penalties with `is_penalty`.
- **Results profile.** Group `fct_matches` by `result` for the home-win, draw and away-win split, and average goals per match.

## Possible extensions

- A `fct_league_table` mart, checked against the real 2015/16 table
- Unnesting event-specific structs into more marts (passes, carries)
- Running the same project on a cloud warehouse (Databricks or BigQuery)
- CI to run `dbt build` on every push

## Data attribution

Data provided by [StatsBomb](https://statsbomb.com). Open data available at [github.com/statsbomb/open-data](https://github.com/statsbomb/open-data), used under StatsBomb's open data terms.
