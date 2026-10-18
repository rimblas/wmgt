-- alter session set PLSQL_CCFLAGS='NOLOGGER:TRUE';
create or replace package body wmg_leaderboard_util
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


gc_scope_prefix constant varchar2(31) := lower($$PLSQL_UNIT) || '.';
subtype scope_t is varchar2(128);

procedure log(
    p_msg  in varchar2
  , p_ctx  in varchar2 default null
)
is
begin
  $IF $$NOLOGGER $THEN
  dbms_output.put_line('[' || p_ctx || '] ' || p_msg);
  apex_debug.message('[%s] %s', p_ctx, p_msg);
  $ELSE
  logger.log(p_text => p_msg, p_scope => p_ctx);
  $END
end log;


/**
 * Given a line to load identify the course.
 *
 * @example
 * select wmg_leaderboard_util.get_course('Mount Olympus - Hard') from dual;
 *
 * @author Jorge Rimblas
 * @created June 30, 2024
 * @param p_line line to load
 * @return course id
 */
function get_course(p_line in varchar2) return number
is
  l_scope constant scope_t := gc_scope_prefix || 'get_course';

  l_course_id wmg_courses.id%type;
  l_error_message varchar2(100);
  l_line varchar2(200);
begin
  -- translations
  l_line := replace(
              replace(
                replace(
                replace(lower(p_line)
                   , 'difficult', 'Hard')
                   , 'dificil', 'Hard')
                   , 'dif' || unistr('\00ed') || 'cil', 'Hard')
                   , 'schwer', 'Hard');

  l_line := case upper(l_line)
    when 'OLYMP' then 'Mount Olympus'
    when 'OLYMP - HARD' then 'Mount Olympus - Hard'
    else l_line end;

  -- Fix Alice in Wonderland.
  if lower(l_line) like 'alice in wonderland%' then
    -- The proper course name is close enough after this for Jaro-Winkler matching.
    l_line := replace(lower(l_line), 'alice in wonderland', 'Alice Adventures In Wonderland');

  elsif lower(l_line) like 'tiki%' then
    if lower(l_line) like '%hard' then
      l_line := 'Tiki ' || unistr('\00e0') || ' Coco - Hard';
    else
      l_line := 'Tiki ' || unistr('\00e0') || ' Coco';
    end if;
  elsif lower(l_line) like 'alicia%' then
    if lower(l_line) like '%hard' then
      l_line := 'Alice Adventures In Wonderland - Hard';
    else
      l_line := 'Alice Adventures In Wonderland';
    end if;
  end if;

  with p as (
    select lower(trim(replace(
            replace(
              replace(
               replace(
                 replace(
                  replace(
                  replace(
                  replace(
                   replace(trim(l_line)
                     , 'Tokio', 'Tokyo')
                     , 'la vuelta al mundo - hard' , 'Around The World - Hard')
                     , 'la vuelta al mundo' , 'Around The World In 80 Days')
                     , 'Around The World In 80 Days - Hard', 'Around The World - Hard')
                     , '20,000 Leagues Under the Sea - Hard', '20,000 Leagues Hard')
                     , 'Wallace And Gromit - Hard', 'Wallace ' || chr(38) || ' Gromit - Hard')
                     , ' - Easy', '')
                     , unistr('\2013') || ' Easy', '')
                     , '(Race Mode)', '')
           )
          )
          course_name
       from dual
  )
  select id
    into l_course_id
    from (
    select id, name, utl_match.jaro_winkler_similarity(lower(name), p.course_name) similarity
      from wmg_courses, p
     where utl_match.jaro_winkler_similarity(lower(name), p.course_name) > 90
    )
    order by similarity desc
    fetch first 1 rows only;

  log('.. course_id:' || l_course_id, l_scope);
  return l_course_id;

exception
  when no_data_found then
    l_error_message := 'Could not find course [' || p_line || ']';
    log('.. ' || l_error_message, l_scope);
    raise_application_error(-20000, l_error_message);
end get_course;


/**
 * Given a name identify the player.
 *
 * @author Jorge Rimblas
 * @created August 31, 2025
 * @param p_name player name
 * @return player id
 */
function get_player(p_name in varchar2) return number
is
  l_scope constant scope_t := gc_scope_prefix || 'get_player';

  l_player_id wmg_players.id%type;
  l_player_name wmg_players.name%type;
begin
  log('.. player name: ' || p_name, l_scope);
  l_player_name := lower(p_name);

  case
    when l_player_name = 'qckmtchqu33n' then
      l_player_name := '6forty2'; -- help with special characters
    when l_player_name = 'gonzonater' or l_player_name = '6onzonater' then
      l_player_name := 'g0nz0nater'; -- help with special characters
    when l_player_name = 'old' || unistr('\2581') || 't' then
      l_player_name := 'old-t';
    when l_player_name in ('500jim', '5oojim') then
      l_player_name := '5.0jim';
    when l_player_name = 'puttnaked' then
      l_player_name := '_ryder_spider_'; -- help with special characters
    when l_player_name = 'puttz ' || unistr('\26be') || ' ' || unistr('\D83C\DFB1')
      or l_player_name = 'puttz' then
      l_player_name := 'puttz2'; -- help with special characters
    else
      null;
  end case;

  log('.. looking for player name: ' || l_player_name, l_scope);

  select id
    into l_player_id
    from (
    select id, player_name
         , greatest(
             nvl(utl_match.jaro_winkler_similarity(lower(player_name), l_player_name), 0)
           , nvl(utl_match.jaro_winkler_similarity(lower(account), l_player_name), 0)
          ) rn
      from wmg_players_v
     where (
           utl_match.jaro_winkler_similarity(lower(player_name), l_player_name) > 85
        or utl_match.jaro_winkler_similarity(lower(account), l_player_name) > 85 -- help with emoji names
      )
    )
    order by rn desc
    fetch first 1 rows only;

  return l_player_id;

exception
  when no_data_found then
    return null;
  when others then
    logger.log_error('Unhandled Exception', l_scope);
    return null;
end get_player;

end wmg_leaderboard_util;
/
