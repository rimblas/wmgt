create or replace view wmg_team_players_v
as
select t.tournament_id
     , t.id        team_id
     , row_number() over (partition by t.tournament_id order by t.team_completed_on, t.id) team_no
     , t.team_name
     , t.team_passcode
     , case when t.verified_by is not null then 'Y' else null end team_verified_flag
     , t.team_logo
     , t.mimetype
     , t.filename
     , t.image_last_update
     , t.verified_by
     , t.verified_on
     , t.verified_note
     , t.team_complete_ind
     , t.active_ind
     , p.id player_id
     , p.discord_id
     , p.player_name
     , count(*) over (partition by t.tournament_id, t.id) player_count
  from wmg_teams t
  join wmg_team_players tp on t.id = tp.team_id
  join wmg_players_v p on tp.player_id = p.id
  where t.team_complete_ind = 'Y'
/