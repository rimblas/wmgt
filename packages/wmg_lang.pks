create or replace package wmg_lang
is



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
  return varchar2;


procedure set_player_language(p_player_id in wmg_players.id%type default null);



end wmg_lang;
/

