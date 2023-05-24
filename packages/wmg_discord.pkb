set define off
create or replace package body wmg_discord
is


--------------------------------------------------------------------------------
-- TYPES
/**
 * @type
 */

-- CONSTANTS
/**
 * @constant gc_scope_prefix Standard logger package name
 */
gc_scope_prefix constant VARCHAR2(31) := lower($$PLSQL_UNIT) || '.';
subtype scope_t is varchar2(128);


/**
 * Log either via logger or apex.debug
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created January 15, 2023
 * @param p_msg
 * @param p_ctx
 * @return
 */
procedure log(
    p_msg  in varchar2
  , p_ctx  in varchar2 default null
)
is
begin
  $IF $$LOGGER $THEN
  logger.log(p_text => p_msg, p_scope => p_ctx);
  $ELSE
  dbms_output.put_line('[' || p_ctx || '] ' || p_msg);
  apex_debug.message('[%s] %s', p_ctx, p_msg);
  $END

end log;



/**
 * Return the URL to a discord avatar
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created January 15, 2023
 * @param p_discord_id
 * @param p_avatar_uri
 * @return
 */
function avatar(
    p_discord_id in wmg_players.discord_id%type
  , p_avatar_uri in wmg_players.discord_avatar%type default null)
return varchar2
is
  l_scope  scope_t := gc_scope_prefix || 'avatar';

  l_avatar wmg_players.discord_avatar%type;
begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  log('BEGIN', l_scope);

  if p_avatar_uri is null then
     select discord_avatar
       into l_avatar
       from wmg_players
      where discord_id = p_discord_id
        and discord_avatar is not null;
  else
    l_avatar := p_avatar_uri;
  end if;

  return 'https://cdn.discordapp.com/avatars/' || p_discord_id|| '/' || l_avatar || '.png';


  log('END', l_scope);

exception
    when no_data_found then
      return V('APP_IMAGES') || '/img/discord_mask.png';

    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end avatar;





/**
 * Return the URL to a discord avatar
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created January 15, 2023
 * @param p_discord_id
 * @param p_avatar_uri
 * @return
 */
function avatar_link(
    p_discord_id in wmg_players.discord_id%type
  , p_avatar_uri in wmg_players.discord_avatar%type default null
  , p_size_class in varchar2 default 'md')
return varchar2
is
  l_scope  scope_t := gc_scope_prefix || 'avatar_link';

begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  log('START', l_scope);

   if p_discord_id is null then
     return '<img class="avatar ' || p_size_class || '" src="' || V('APP_IMAGES') || '/img/discord_mask.png' || '">';
   else
     -- return '<a class="-wm-discord-link" href="discord://discordapp.com/users/' || p_discord_id || '/">'
     return '<a class="-wm-discord-link" href="https://discordapp.com/users/' || p_discord_id || '/" target="discord">'
          || '<img class="avatar ' || p_size_class || '" src="' || avatar(p_discord_id => p_discord_id, p_avatar_uri => p_avatar_uri) || '">'
          || '</a>';
   end if;

exception
    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end avatar_link;





/**
 * Return the HTML to render a player profile
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created April 13, 2023
 * @param p_player_id
 * @param p_avatar_uri
 * @return
 */
function render_profile(
    p_player_id  in wmg_players.id%type
  , p_mode       in varchar2             default 'FULL'
  , p_spacing    in varchar2             default 'FULL'
)
return varchar2
is
  l_scope  scope_t := gc_scope_prefix || 'render_profile';

  l_cols  varchar2(10);

begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  log('BEGIN', l_scope);

  if p_player_id is null then
    -- we don't have a player yet
    return '<img class="avatar md" src="' || wmg_discord.avatar(nv('G_DISCORD_ID')) || '"</> Player not setup.';
  end if;


  if p_spacing = 'FULL' then 
    l_cols := 'col-12';
  else
    l_cols := 'col-3';
  end if;

  for p in (
  select p.player_name
       , case when discord_id is not null then
          '<a href="discord://discordapp.com/users/' || p.discord_id || '/">'
          || '<img class="avatar ' || case when  p_mode = 'MINI' then 'md' else 'lg' end || '" src="' || wmg_discord.avatar(p_discord_id => p.discord_id, p_avatar_uri => p.discord_avatar) || '">'
          || '</a>' 
         else '' end discord_profile
       , '<i class="' || case when  p_mode = 'MINI' then 'margin-top-sm' end || ' flag em-svg em-flag-' || p.country_code || '" aria-role="presentation" aria-label="' || p.COUNTRY_CODE || ' Flag"></i>' flag
       , p.rank_name
       , p.rank_profile_class
       , p.country
       , p.prefered_tz
    from wmg_players_v p
   where p.id = p_player_id
  )
  loop
    if p_mode = 'MINI' then
      return '<div class="row col-6 col-md-8 u-justify-content-space-around">' || p.discord_profile 
          || ' &nbsp; <span class="' || p.rank_profile_class || '">' || p.rank_name || '</span>'
          || p.flag
      || '</div>';
    else
      return '<div class="row">'
         || '<div class="' || l_cols || ' u-tC">'
         ||   p.discord_profile
         || '<h3>' || p.player_name || '</h3>'
         || '<div class="' || p.rank_profile_class || '">' || p.rank_name || '</div>'
         || '</div></div>'
         || '<div class="row">'
         || '<div class="' || l_cols || ' u-tC">'
         || p.flag || '<br>' || p.country || '<br><hr>' || p.prefered_tz
         || '</div></div>';
     end if;
  end loop;

  log('END', l_scope);

exception
    when no_data_found then
      return V('APP_IMAGES') || '/img/discord_mask.png';

    when OTHERS then
      log('Unhandled Exception', l_scope);
      return 
      '<div class="row">'
         || '<div class="' || l_cols || ' u-tC">'
         || '<img class="avatar" src="' || v('APP_IMAGES') || '/img/discord_mask.png' || '">'
         || ' Something went wrong retriving your profile. Plese let a Tournament Director know.'
         || '</div>'
     || '</div>';
end render_profile;



procedure merge_players(
    p_from_player_id  in wmg_players.id%type
  , p_into_player_id  in wmg_players.id%type
  , p_remove_from_player in boolean default true
)
is
  l_scope  scope_t := gc_scope_prefix || 'merge_players';

  l_player_rec wmg_players%rowtype;

begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  log('BEGIN', l_scope);

  select *
    into l_player_rec
    from wmg_players
   where id = p_from_player_id;


  log('.. clear previous values from source player', l_scope);
  -- need to clear because some of these values are unique
  update wmg_players
     set account = 'Merged into ' || p_into_player_id
       , name = null
       , account_login = null
       , prefered_tz = null
       , discord_id = null
       , discord_avatar = null
       , discord_discriminator = null
   where id = p_from_player_id;

  log('.. Link to correct player', l_scope);
  update wmg_players
     set account = l_player_rec.account
       , name = l_player_rec.name
       , account_login = l_player_rec.account_login
       , prefered_tz = l_player_rec.prefered_tz
       , country_code = l_player_rec.country_code
       , discord_id = l_player_rec.discord_id
       , discord_avatar = l_player_rec.discord_avatar
       , discord_discriminator = l_player_rec.discord_discriminator
   where id = p_into_player_id
     and discord_id is null;

  log('.. Move tournament registration', l_scope);
  update wmg_tournament_players
     set player_id = p_into_player_id
   where player_id = p_from_player_id;

  update wmg_rounds
     set players_id = p_into_player_id
   where players_id = p_from_player_id;

  if p_remove_from_player then
    delete
      from wmg_players
     where id = p_from_player_id;
  end if;


  log('END', l_scope);
end merge_players;


end wmg_discord;
/
