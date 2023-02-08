create or replace package wmg_util
is


--------------------------------------------------------------------------------
--*
--* 
--*
--------------------------------------------------------------------------------

type rec_keyval_type is record(
    key      varchar2(10)
  , val      varchar2(250)
);

type tab_keyval_type is table of rec_keyval_type;


function rooms_set(p_tournament_session_id in wmg_tournament_sessions.id%type )
   return varchar2;

--------------------------------------------------------------------------------
procedure assign_rooms(
    p_tournament_session_id  in wmg_tournament_sessions.id%type
);


procedure possible_player_match (
    p_discord_account in wmg_players.account%type
  , p_discord_id      in wmg_players.discord_id%type
  , x_players_tbl     in out nocopy tab_keyval_type
);


end wmg_util;
/
