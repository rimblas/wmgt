create or replace package wmg_notification
is


--------------------------------------------------------------------------------
--*
--* 
--*
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------

procedure new_player(
    p_player_id       in wmg_players.id%type
  , p_registration_id in wmg_tournament_players.id%type default null
);

procedure notify_room_assignments(
    p_tournament_session_id  in wmg_tournament_sessions.id%type
);

procedure notify_new_courses(
    p_tournament_session_id  in wmg_tournament_sessions.id%type
);

end wmg_notification;
/
