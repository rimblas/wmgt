create or replace package wmg_discord
is


--------------------------------------------------------------------------------
--*
--* 
--*
--------------------------------------------------------------------------------


function avatar(
    p_discord_id in wmg_players.discord_id%type
  , p_avatar_uri in wmg_players.discord_avatar%type default null)
return varchar2;

--------------------------------------------------------------------------------


end wmg_discord;
/
