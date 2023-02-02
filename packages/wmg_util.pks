create or replace package wmg_util
is


--------------------------------------------------------------------------------
--*
--* 
--*
--------------------------------------------------------------------------------

function rooms_set(p_tournament_session_id in wmg_tournament_sessions.id%type )
   return varchar2;

--------------------------------------------------------------------------------
procedure assign_rooms(
    p_tournament_session_id  in wmg_tournament_sessions.id%type
);


end wmg_util;
/
