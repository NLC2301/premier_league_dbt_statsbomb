with matches as (

    select * from {{ ref('stg_statsbomb__matches') }}

)

select
    *,
    home_score + away_score as total_goals,
    case
        when home_score > away_score then 'home_win'
        when home_score < away_score then 'away_win'
        else 'draw'
    end as result,
    case
        when home_score > away_score then home_team_name
        when home_score < away_score then away_team_name
    end as winning_team_name,
    case
        when home_score > away_score then 3
        when home_score < away_score then 0
        else 1
    end as home_points,
    case
        when home_score > away_score then 0
        when home_score < away_score then 3
        else 1
    end as away_points

from matches