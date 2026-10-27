with source as (

    select * from {{ source('statsbomb', 'matches') }}

),

renamed as (

    select
        s.match_id,
        s.match_date::date as match_date,
        s.kick_off,
        s.match_week,

        s.competition.competition_id as competition_id,
        s.competition.competition_name as competition_name,
        s.season.season_id as season_id,
        s.season.season_name as season_name,

        s.home_team.home_team_id as home_team_id,
        s.home_team.home_team_name as home_team_name,
        s.away_team.away_team_id as away_team_id,
        s.away_team.away_team_name as away_team_name,

        s.home_score,
        s.away_score,

        s.stadium.name as stadium_name,
        s.referee.name as referee_name

    from source as s

)

select * from renamed
