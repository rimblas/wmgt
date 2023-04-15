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

function render_profile(
    p_player_id  in wmg_players.id%type
  , p_mode       in varchar2             default 'FULL'
  , p_spacing    in varchar2             default 'FULL'
)
return varchar2;

end wmg_discord;
/
