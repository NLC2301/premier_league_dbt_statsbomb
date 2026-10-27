select *
from {{ ref('fct_matches') }}
where home_points + away_points not in (2, 3)