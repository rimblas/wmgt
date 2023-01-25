create or replace view wmg_tournament_player_v
as
select t.id                              tournament_id
     , t.code                            code
     , t.name                            name
     , t.prefix_tournament               prefix_tournament
     , t.prefix_session                  prefix_session
     , t.current_flag                    current_flag
     , t.active_ind                      active_ind
     , t.url                             url
     , t.notes                           notes
     , t.created_on                      tournament_created
     , t.created_by                      tournament_created_by
     , t.updated_on                      tournament_updated
     , t.updated_by                      tournament_updated_by
     , ts.id                             tournament_session_id
     , ts.round_num                      round_num
     , ts.session_date                   session_date
     , ts.week                           week
     , ts.open_registration_on           open_registration_on
     , ts.close_registration_on          close_registration_on
     , ts.completed_ind                  completed_ind
     , ts.completed_on                   completed_on
     , ts.created_on                     tournament_session_created
     , ts.created_by                     tournament_session_created_by
     , ts.updated_on                     tournament_session_updated
     , ts.updated_by                     tournament_session_updated_by
     , tp.id                             tournament_player_id
     , tp.time_slot                      time_slot
     , tp.room_no                        room_no
     , tp.created_on                     tournament_player_created
     , tp.created_by                     tournament_player_created_by
     , tp.updated_on                     tournament_player_updated
     , tp.updated_by                     tournament_player_updated_by
     , p.id                              player_id
     , p.account                         account
     , p.country_code                    country_code
  from wmg_tournaments t
     , wmg_tournament_sessions ts
     , wmg_tournament_players tp
     , wmg_players p
 where ts.tournament_id(+) = t.id
   and tp.tournament_session_id(+) = ts.id 
   and tp.player_id = p.id(+)
/
