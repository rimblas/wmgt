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
  -- dbms_output.put_line('[' || p_ctx || '] ' || p_msg);
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
      where discord_id = p_discord_id;
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




end wmg_discord;
/
