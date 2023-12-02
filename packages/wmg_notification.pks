create or replace package wmg_notification
is


--------------------------------------------------------------------------------
--*
--* 
--*
--------------------------------------------------------------------------------


procedure send_to_discord_webhook(
    p_webhook_code    in wmg_webhooks.code%type
  , p_content         in clob
  , p_embeds          in clob default null
  , p_user_name       in wmg_players.account%type default null
);

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

procedure tournament_recap_template(
    p_tournament_session_id  in wmg_tournament_sessions.id%type
  , x_out                    out clob
);

end wmg_notification;
/
