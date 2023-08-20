-- Add tournament players
begin

-- update wmg_rounds r
-- set r.final_score = (select rv.scorecard_total from wmg_rounds_v rv where rv.round_id = r.id)
-- where r.week = 'S05W08'
-- and r.final_score is null
-- /

    -- performing data loads so skip the MUST BE CURRENT validation
    wmg_util.g_must_be_current := false;

  for ts in (
    select *
       from wmg_tournament_sessions
      where week like 'S04%'
  )
  loop



    delete from wmg_tournament_players where tournament_session_id = ts.id;
    delete from wmg_player_badges where tournament_session_id = ts.id
       and badge_type_code in ('COCONUT', 'CACTUS'
           , 'FIRST'
           , 'SECOND'
           , 'THIRD'
           , 'TOP10'
      ) ;
    insert into wmg_tournament_players
    (    
        tournament_session_id
      , player_id
      , time_slot
      , active_ind
    )
    select distinct 
           ts.id
         , r.players_id
         , '00:00' time_slot
         , 'Y'     active_ind
      from wmg_rounds r
     where r.week = ts.week;


     wmg_util.close_tournament_session(
        p_tournament_id => ts.tournament_id
      , p_tournament_session_id => ts.id
     );

  end loop;

end;
/
