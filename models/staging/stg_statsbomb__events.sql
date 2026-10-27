with source as (

    select * from {{ source('statsbomb', 'events') }}

),

renamed as (

    select
        s.id as event_id,
        s.match_id,
        s."index" as event_index,
        s.period,
        s."minute",
        s."second",
        s."timestamp" as event_timestamp,
        s.duration,

        s."type".id as event_type_id,
        s."type".name as event_type,
        s.play_pattern.name as play_pattern,
        s.possession,
        s.possession_team.id as possession_team_id,
        s.possession_team.name as possession_team_name,

        s.team.id as team_id,
        s.team.name as team_name,
        s.player.id as player_id,
        s.player.name as player_name,
        s.position.name as position_name,

        s.location[1] as location_x,
        s.location[2] as location_y,

        -- booleans are null when false, so make that explicit
        coalesce(s.under_pressure, false) as is_under_pressure,
        coalesce(s.counterpress, false) as is_counterpress,
        coalesce(s.off_camera, false) as is_off_camera,
        coalesce(s."out", false) as is_out,

        s.related_events,

        -- event-specific details, left nested for now
        s.pass,
        s.shot,
        s.carry,
        s.dribble,
        s.duel,
        s.ball_receipt,
        s.clearance,
        s.interception,
        s.goalkeeper,
        s.block,
        s.foul_committed,
        s.foul_won,
        s.ball_recovery,
        s.injury_stoppage,
        s.substitution,
        s.bad_behaviour,
        s.miscontrol,
        s."50_50" as fifty_fifty,
        s.player_off,
        s.half_start,
        s.tactics

    from source as s

)

select * from renamed