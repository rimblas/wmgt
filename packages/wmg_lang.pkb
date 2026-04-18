create or replace package body wmg_lang
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



------------------------------------------------------------------------------
/**
 * Create JSON list of languages to be used by the JTL Item plugin
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created November 4, 2016
 * @param
 * @return list of languages (i.e ["en","fr-ca","es"])
 */
function installed_languages
  return varchar2
is
  l_scope  logger_logs.scope%type := gc_scope_prefix || 'installed_languages';
  l_params logger.tab_param;

  l_lang_list  varchar2(1000);
begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  -- logger.log('START', l_scope, null, l_params);

  select '[' || listagg('"' || code || '"', ',') within group (order by display_seq) || ']'
    into l_lang_list
   from wmg_languages
  where installed_ind = 'Y';

  return l_lang_list;
  
  exception
    when OTHERS then
      logger.log_error('Unhandled Exception', l_scope, null, l_params);
      raise;
end installed_languages;


/**
 * Set the default player language is present
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created April 11, 2026
 * @param p_player_id
 * @return
 */
procedure set_player_language(p_player_id in wmg_players.id%type default null)
is
  l_scope  logger_logs.scope%type := gc_scope_prefix || 'set_player_language';
  l_params logger.tab_param;

  l_lang varchar2(20);
begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  logger.log('BEGIN', l_scope, null, l_params);

  for p in (
    select prefered_lang from wmg_players where id = p_player_id and prefered_lang is not null
  )
  loop
    l_lang := p.prefered_lang;
    logger.log('.. Found prefered_lang: ' || l_lang, l_scope);
  end loop;

  if l_lang is null then
    -- find if the language is different from English
    logger.log('.. HTTP_ACCEPT_LANGUAGE: ' || owa_util.get_cgi_env('HTTP_ACCEPT_LANGUAGE'), l_scope);
    l_lang := lower(substr(owa_util.get_cgi_env('HTTP_ACCEPT_LANGUAGE'), 1, 2));
    logger.log('.. new l_lang: ' || l_lang, l_scope);
    l_lang := case
                when l_lang = 'es' then 'es'
                when l_lang = 'fr' then 'fr'
                else 'en'
              end;
  end if;

  logger.log('.. Setting lang: ' || l_lang, l_scope);  
  apex_util.set_session_lang(l_lang);

  logger.log('END', l_scope, null, l_params);

  exception
    when OTHERS then
      logger.log_error('Unhandled Exception', l_scope, null, l_params);
      raise;
end set_player_language;



end wmg_lang;
/

