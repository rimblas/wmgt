create or replace package wmg_leaderboard_util
is

--------------------------------------------------------------------------------
--*
--* Minimal FHIT-local leaderboard utility.
--*
--* This package intentionally exposes only the lookup helpers required by
--* wmg_verification_engine. Compile it in the FHIT schema so unqualified
--* references resolve to FHIT.wmg_courses and FHIT.wmg_players.
--*
--------------------------------------------------------------------------------

function get_course(p_line in varchar2) return number;
function get_player(p_name in varchar2) return number;

end wmg_leaderboard_util;
/
