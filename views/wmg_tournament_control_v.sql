create or replace view wmg_tournament_control_v as
select tc.tournament_type_code
     , tc.tournament_session_id
     , ts.tournament_id
     , ts.round_num
     , ts.session_date
     , ts.week
     , ts.open_registration_on
     , ts.close_registration_on
     , ts.registration_closed_flag
     , ts.rooms_open_flag
     , ts.rooms_defined_flag
     , ts.rooms_defined_by
     , ts.rooms_defined_on
     , ts.completed_ind
     , ts.completed_on
     , t.name as tournament_name
     , t.code as tournament_code
     , t.prefix_tournament
     , t.prefix_session
     , t.current_flag
     , t.active_ind
     , t.url
     , t.prefix_room_name
     , t.start_date
     , tc.created_on as control_created_on
     , tc.created_by as control_created_by
     , tc.updated_on as control_updated_on
     , tc.updated_by as control_updated_by
  from wmg_tournament_control tc
  left join wmg_tournament_sessions ts on tc.tournament_session_id = ts.id
  left join wmg_tournaments t on ts.tournament_id = t.id
/