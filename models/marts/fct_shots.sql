with shots as (

    select * from {{ ref('stg_statsbomb__events') }}
    where event_type = 'Shot'

)

select
    event_id,
    match_id,
    period,
    "minute",
    "second",

    team_id,
    team_name,
    player_id,
    player_name,
    position_name,

    location_x,
    location_y,
    shot.end_location[1] as end_location_x,
    shot.end_location[2] as end_location_y,

    shot.statsbomb_xg as xg,
    shot.outcome.name as shot_outcome,
    shot."type".name as shot_type,
    shot.body_part.name as body_part,
    shot.technique.name as technique,
    shot.one_on_one as is_one_on_one,
    shot.deflected as is_deflected,
    coalesce(shot.first_time, false) as is_first_time,

    shot.outcome.name = 'Goal' as is_goal,
    shot."type".name = 'Penalty' as is_penalty

from shots