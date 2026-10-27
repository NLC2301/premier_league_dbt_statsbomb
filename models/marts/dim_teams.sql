with home as (

    select home_team_id as team_id, home_team_name as team_name
    from {{ ref('stg_statsbomb__matches') }}

),

away as (

    select away_team_id as team_id, away_team_name as team_name
    from {{ ref('stg_statsbomb__matches') }}

)

select team_id, team_name from home
union
select team_id, team_name from away