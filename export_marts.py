import duckdb
from pathlib import Path

Path("exports").mkdir(exist_ok=True)
con = duckdb.connect("football.duckdb", read_only=True)
for t in ["dim_teams", "fct_matches", "fct_shots"]:
    con.execute(f"copy main.{t} to 'exports/{t}.parquet' (format parquet)")
    print(f"exported {t}")
con.close()