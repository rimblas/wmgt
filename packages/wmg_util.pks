create or replace package wmg_util
is


--------------------------------------------------------------------------------
--*
--* 
--*
--------------------------------------------------------------------------------

e_not_current_tournament constant number := -20000;
e_not_correct_session    constant number := -20001;


type rec_keyval_type is record(
    key      varchar2(10)
  , val      varchar2(250)
);

type tab_keyval_type is table of rec_keyval_type;


function rooms_set(p_tournament_session_id in wmg_tournament_sessions.id%type )
   return varchar2;

--------------------------------------------------------------------------------
function get_param(
  p_name_key  in wmg_parameters.name_key%TYPE
)
return varchar2;

--------------------------------------------------------------------------------
procedure set_param(
    p_name_key  in wmg_parameters.name_key%TYPE
  , p_value     in wmg_parameters.value%TYPE
);

--------------------------------------------------------------------------------
procedure assign_rooms(
    p_tournament_session_id  in wmg_tournament_sessions.id%type
);

procedure reset_room_assignments(
    p_tournament_session_id  in wmg_tournament_sessions.id%type
);

procedure possible_player_match (
    p_discord_account in wmg_players.account%type
  , p_discord_id      in wmg_players.discord_id%type
  , x_players_tbl     in out nocopy tab_keyval_type
);

procedure snapshot_badges (
    p_tournament_id         in wmg_tournaments.id%type
  , p_tournament_session_id in wmg_tournament_sessions.id%type
);

procedure close_tournament_session (
    p_tournament_id         in wmg_tournaments.id%type
  , p_tournament_session_id in wmg_tournament_sessions.id%type
);

function score_points(
    p_rank         in number
  , p_percent_rank in number
  , p_player_count in number
)
return number;

--------------------------------------------------------------------------------
procedure score_entry_verification(
   p_week      in wmg_rounds.week%type
 , p_player_id in wmg_players.id%type
 , p_course_id in number default null
 , p_remove    in boolean default false
);

procedure unavailable_application (p_message in varchar2 default null);

end wmg_util;
/
