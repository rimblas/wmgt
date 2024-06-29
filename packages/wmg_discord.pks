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

function avatar_link(
    p_discord_id in wmg_players.discord_id%type
  , p_avatar_uri in wmg_players.discord_avatar%type default null
  , p_size_class in varchar2 default 'md')
return varchar2;

function guild_link(
    p_discord_id in wmg_guilds.discord_id%type
  , p_avatar_uri in wmg_guilds.discord_avatar%type default null
  , p_size_class in varchar2 default 'md')
return varchar2;

--------------------------------------------------------------------------------

function render_profile(
    p_player_id  in wmg_players.id%type
  , p_mode       in varchar2             default 'FULL'
  , p_spacing    in varchar2             default 'FULL'
)
return varchar2;

procedure merge_players(
    p_from_player_id  in wmg_players.id%type
  , p_into_player_id  in wmg_players.id%type
  , p_remove_from_player in boolean default true
);

end wmg_discord;
/
