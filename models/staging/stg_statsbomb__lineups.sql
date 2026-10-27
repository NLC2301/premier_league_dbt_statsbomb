with source as (

    select * from {{ source('statsbomb', 'lineups') }}

),

unnested as (

    select
        match_id,
        team_id,
        team_name,
        unnest(lineup) as player
    from source

),

renamed as (

    select
        match_id,
        team_id,
        team_name,
        player.player_id as player_id,
        player.player_name as player_name,
        player.player_nickname as player_nickname,
        player.jersey_number as jersey_number,
        player.country.name as country_name,

        -- lists of structs, left nested for now due to players most likely having more than one card or position
        player.cards,
        player.positions

    from unnested

)

select * from renamed