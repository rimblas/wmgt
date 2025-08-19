-- alter session set PLSQL_CCFLAGS='NOLOGGER:TRUE';
create or replace package body wmg_util
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

c_issue_noshow     constant wmg_tournament_players.issue_code%type := 'NOSHOW';
c_issue_noscore    constant wmg_tournament_players.issue_code%type := 'NOSCORE';
c_issue_infraction constant wmg_tournament_players.issue_code%type := 'INFRACTION';


g_rooms_set_ind wmg_tournament_sessions.rooms_defined_flag%type;


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
  -- $IF logger_logs.g_logger_version is not null $THEN
  $IF $$NOLOGGER $THEN
  dbms_output.put_line('[' || p_ctx || '] ' || p_msg);
  apex_debug.message('[%s] %s', p_ctx, p_msg);
  $ELSE
  logger.log(p_text => p_msg, p_scope => p_ctx);
  $END

end log;


function rooms(p_player_count in number) return number
is
   l_players integer;
   l_rooms number;
begin
  l_players := nvl(p_player_count, 0);
  l_rooms := trunc(l_players / 4);

  return 
      case 
        when l_rooms  =  (l_players / 4) then l_rooms  -- evenly divisible by 4
        else
          l_rooms + 1
      end;

/*
when p_player_count = 5 then 1 --  Rooms 3 + 2
when p_player_count = 6 then 1 --  Rooms 3 + 3
when p_player_count = 7 then 1 --  Rooms 3 + 3
when p_player_count = 8 then 1 --  Rooms 4 + 4
when p_player_count = 9 then 1 --  Rooms 3 + 3 + 3
*/

end rooms;


/**
 * Given a Tournament Session return Y when the Rooms are set and defined
 * N when they are not
 *
 *
 * @example
 *   :G_CURRENT_SESSION_ID is not null and (:G_REGISTRATION_ID is not null) and wmg_util.rooms_set(:G_CURRENT_SESSION_ID) = 'N'
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created 
 * @param tournament_session_id 
 * @return Y/N
 */
function rooms_set(p_tournament_session_id in wmg_tournament_sessions.id%type )
   return varchar2
is
  l_scope  scope_t := gc_scope_prefix || 'rooms_set';
  l_rooms_defined_flag wmg_tournament_sessions.rooms_defined_flag%type;
begin
  $IF $$VERBOSE_OUTPUT $THEN
  log('START', l_scope);
  log('g_rooms_set_ind:' || g_rooms_set_ind, l_scope);
  $END

  if g_rooms_set_ind is null then
    $IF $$VERBOSE_OUTPUT $THEN
    log('fetch new rooms_defined_flag:', l_scope);
    $END
    select nvl(rooms_defined_flag, 'N')
      into l_rooms_defined_flag
      from wmg_tournament_sessions 
     where id = p_tournament_session_id;

    g_rooms_set_ind := l_rooms_defined_flag;
  end if;
   
  return g_rooms_set_ind;

  exception
    when no_data_found then
      g_rooms_set_ind := 'N';
      return g_rooms_set_ind;
    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end rooms_set;



------------------------------------------------------------------------------
/**
 * Get parameter values
 *
 *
 * @example
 * wmg_util.get_param('EMAIL_OVERRIDE')
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created November 8, 2016
 * @param
 * @return
 */
function get_param(
  p_name_key  in wmg_parameters.name_key%TYPE
)
return varchar2
is
  l_value wmg_parameters.value%TYPE;
begin

  select value
    into l_value
    from wmg_parameters
   where name_key = p_name_key;

  return l_value;

exception
  when NO_DATA_FOUND then
    return null;

end get_param;





/**
 * Set a parameter value
 *
 *
 * @example
 * wmg_util.set_param('EMAIL_OVERRIDE', 'developers_list@insum.ca')
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created November 8, 2016
 * @param
 * @return
 */
procedure set_param(
    p_name_key      in wmg_parameters.name_key%TYPE
  , p_value         in wmg_parameters.value%TYPE
)
is
begin

  update wmg_parameters
     set value = p_value
   where name_key = p_name_key;

  if sql%rowcount = 0 then
    raise_application_error(
        -20001
      , 'Parameter ' || p_name_key || ' does not exist.'
    );
  end if;

end set_param;



------------------------------------------------------------------------------
function extract_hole_from_file(p_filename in varchar2) 
  return number
is
  l_scope  scope_t := gc_scope_prefix || 'extract_hole_from_file';
  f apex_t_varchar2;
begin
  -- log('START', l_scope);
  f :=  apex_string.split(p_filename, '.');
  return to_number(apex_string.split(f(1), '_')(2) default null on conversion error);
exception 
when others then 
  return p_filename;
end extract_hole_from_file;




------------------------------------------------------------------------------
/**
 * Given a tournament session create random room assignments
 * We ideally want rooms of 4, never have a room of 1 and avoid rooms of 2
 * Scenarios:
 *   1 players: Room  1
 *   2 players: Room  2
 *   3 players: Room  3
 *   4 players: Room  4
 *   5 players: Rooms 3 + 2
 *   6 players: Rooms 3 + 3
 *   7 players: Rooms 4 + 3
 *   8 players: Rooms 4 + 4
 *   9 players: Rooms 3 + 3 + 3
 *  10 players: Rooms 4 + 3 + 3
 *  11 players: Rooms 4 + 4 + 3 = Rule 8 + 3
 *  12 players: Rooms 4 + 4 + 4 = Rule 8 + 4
 *  
 *  Logic:
 *   if P / 4 = trunc(P/4) then even number...
 *   else
 *       Rooms = P / 3 
 *       
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created January 15, 2023
 * @param p_tournament_session_id
 * @return
 */
procedure assign_rooms(
    p_tournament_session_id  in wmg_tournament_sessions.id%type
)
is
  l_scope  scope_t := gc_scope_prefix || 'assign_rooms';

  type room_rec_type is record (
      player_id  wmg_tournament_players.id%TYPE
    , room_no    number
  );

  type room_tbl_type is table of room_rec_type;
  l_room_id_tbl room_tbl_type := room_tbl_type();

  l_seed varchar2(100);
  l_rooms number;
  l_room  number;
  l_room_no  number;       -- sequence for the room that does not reset.
  l_last_room_no  number;  -- last room in the current slot that matches the l_room_no

  l_players  number;
  l_next_player  number;


  -- Search in l_room_id_tbl for a plaer without a room assignment
  function get_next_player return number
  is
    l_next_player number;
    l_player number;
    i number := 0;
    l_max number := l_room_id_tbl.count;
  begin

    l_player := trunc(dbms_random.value(1,l_room_id_tbl.count));
    loop
      i := i + 1;
      -- exit if the player's room has not been assigned and we're below the max number of player
      exit when l_room_id_tbl(l_player).room_no is null and i <= l_max;
      l_player := l_player + 1;
      if l_player > l_max then
        l_player := 1;
      end if;  
    end loop;

    $IF $$VERBOSE_OUTPUT $THEN
    log('.. tries ' || i || ', player ' || l_player, 'get_next_player()');
    $END    

    return l_player;
  end get_next_player;



  function players_on_room(p_room_no in number) return number
  is
    c number := 0;
  begin
    for i in 1 .. l_room_id_tbl.count
    loop
      if l_room_id_tbl(i).room_no = p_room_no then
        c:=c+1;
      end if;
    end loop;
    return c;
  end players_on_room;

begin
  log('BEGIN', l_scope);

  log('.. Stamp room assignments', l_scope);
  update wmg_tournament_sessions
     set rooms_defined_flag = 'Y' -- this will block new registrations
       , rooms_defined_by   = coalesce(sys_context('APEX$SESSION','APP_USER'),user) 
       , rooms_defined_on   = current_timestamp
    where id = p_tournament_session_id;

  commit; -- make sure no new registrations are accepted.

  -- Seed the random number generator
  l_seed := to_char(systimestamp,'YYYYDDMMHH24MISSFFFF');
  dbms_random.seed (val => l_seed);

  l_room_no := 1;       -- start with room 1
  

  for time_slots in (
    with slots_n as (
        select level n
         from dual
         connect by level <= 6
        )
    , slots as (
        select day_offset, slot || ':00' d, slot t
        from (
            select lpad( (n-1)*4,2,0) slot, 0 day_offset
            from slots_n
            union all
            select '22' slot, -1 day_offset from dual
            union all
            select '02' slot, 0 day_offset from dual
            union all
            select '18' slot, 0 day_offset from dual
        )
    )
    select day_offset, d time_slot, t
    from slots
    order by day_offset, t
  )
  loop

    select id, to_number(null) room_no
      bulk collect into l_room_id_tbl
      from wmg_tournament_players
     where tournament_session_id = p_tournament_session_id
       and time_slot = time_slots.time_slot
       and active_ind = 'Y';

    log('.. Assigning Rooms for ' || time_slots.time_slot || ' players ' || l_room_id_tbl.count, l_scope);
    
    l_players := l_room_id_tbl.count;
    l_rooms := rooms(p_player_count => l_players);
    l_room := 1;
    l_last_room_no := l_room_no;  -- Keep this in sync with room_no to indicate where the time slot starts

    log('.. Will need ' || l_rooms || ' Rooms', l_scope);

    <<room_distribution>>
    while l_players > 0
    loop

      
      if l_rooms = 1 then
        -- hey we only have one room, just assign the available players
        l_next_player := l_players;
      else
        l_next_player := get_next_player();
      end if;
      -- l_room_id_tbl(l_next_player).room_no := l_room;
      l_room_id_tbl(l_next_player).room_no := l_room_no;

      log('.. Room ' || l_room || ' = ' || players_on_room(l_room_no) || ' player(s)', l_scope);

      l_room := l_room + 1;  -- next room
      l_room_no := l_room_no + 1;  -- next room

      if l_room > l_rooms then
        l_room := 1;
        l_room_no := l_last_room_no; -- reset the room
      end if;

      l_players := l_players -1;

    end loop room_distribution;


    log('.. Saving room assignments', l_scope);
    forall idx in 1 .. l_room_id_tbl.count
      update wmg_tournament_players
        set room_no = l_room_id_tbl(idx).room_no
       where tournament_session_id = p_tournament_session_id
         and time_slot = time_slots.time_slot
         and id = l_room_id_tbl(idx).player_id;

    -- Make absolutely sure the next room_no in the sequence is brand new
    select max(room_no) + 1
      into l_room_no
      from wmg_tournament_players
     where tournament_session_id = p_tournament_session_id
       and time_slot = time_slots.time_slot;

  end loop; 


  log('.. Stamp room assignments date', l_scope);
  update wmg_tournament_sessions
     set rooms_defined_on   = current_timestamp
    where id = p_tournament_session_id;

  log('END', l_scope);

  exception
    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end assign_rooms;






/**
 * Given a tournament session and after `assign_rooms` has been called
 * it's time to:
 *  * Open the rooms for all players
 *  * Define any new rooms (in wmg_tournament_rooms) that may have been manually added. This is used for verification status
 *  * Schedule the jobs that will close score entering
 *  * Send out room assignment push notifications
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created May 26, 2024
 * @param p_tournament_session_id
 * @return
 */
procedure open_rooms(
    p_tournament_session_id  in wmg_tournament_sessions.id%type
)
is
  l_scope  scope_t := gc_scope_prefix || 'open_rooms';
begin

  log('BEGIN', l_scope);


  log('.. Add rooms for verification', l_scope);
  insert into wmg_tournament_rooms (
      tournament_session_id
    , time_slot
    , room_no
  )
  select distinct tournament_session_id
       , time_slot
       , room_no
    from wmg_tournament_players
   where tournament_session_id = p_tournament_session_id
     and active_ind = 'Y';


  update wmg_tournament_sessions
     set rooms_open_flag = decode(rooms_open_flag, 'Y', null, 'Y')
       , registration_closed_flag = decode(registration_closed_flag, 'Y', null, 'Y')
  where id = p_tournament_session_id;

  commit;  -- Make sure the room open up regardless or other errors

  wmg_util.submit_close_scoring_jobs(p_tournament_session_id => p_tournament_session_id);

  wmg_notification.notify_room_assignments(p_tournament_session_id => p_tournament_session_id);


  log('END', l_scope);

  exception
    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end open_rooms;






/**
 * Given a tournament session reset the room assignments and re-open registrations
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created April 8, 2023
 * @param p_tournament_session_id
 * @return
 */
procedure reset_room_assignments(
    p_tournament_session_id  in wmg_tournament_sessions.id%type
)
is
  l_scope  scope_t := gc_scope_prefix || 'reset_room_assignments';
  -- l_params logger.tab_param;

begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  log('BEGIN', l_scope);

  log('.. removing room assignments', l_scope);
  update wmg_tournament_players
     set room_no = null
       , verified_score_flag = null
       , verified_by = null
       , verified_on = null
   where tournament_session_id = p_tournament_session_id;


  log('.. removing rooms', l_scope);
  delete from wmg_tournament_rooms where tournament_session_id = p_tournament_session_id;

  log('.. Undo room set flags and reset', l_scope);
  update wmg_tournament_sessions
  set rooms_open_flag = null
    , rooms_defined_flag = null
    , rooms_defined_by = null
    , rooms_defined_on = null
    , registration_closed_flag = null
    , completed_ind = 'N'
  where id = p_tournament_session_id;


  log('END', l_scope);

  exception
    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end reset_room_assignments;






/**
 * Given a Discord ID see if this player's name matches one of the existing
 * players.
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created 
 * @param p_discord_id
 * @return
 */
procedure possible_player_match (
    p_discord_account in wmg_players.account%type
  , p_discord_name    in wmg_players.name%type
  , p_discord_id      in wmg_players.discord_id%type
  , x_players_tbl     in out nocopy tab_keyval_type
)
is
  l_scope  scope_t := gc_scope_prefix || 'possible_player_match';

  l_players_arr  varchar2(32767);
  l_players_tbl  tab_keyval_type := tab_keyval_type();
  l_found number := 0;

begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  log('BEGIN', l_scope);


  if p_discord_id is null then
    null;  -- player is already match to a discord id
  else

    begin
      select 1 into l_found from wmg_players where discord_id = p_discord_id;
    exception
      when no_data_found then
        l_players_arr := null;
    end;

    if l_found = 0 then

      select id, player_name
       bulk collect into l_players_tbl
      from (
          select p.id, p.player_name
               , greatest(
                   utl_match.jaro_winkler_similarity(upper(p_discord_account), upper(p.player_name))
                 , utl_match.jaro_winkler_similarity(upper(p_discord_name), upper(p.player_name))
                 ) similarity
            from wmg_players_v p
           where discord_id is null
      )
      where similarity >= 74
      order by similarity desc
      fetch first 5 rows only;

    end if;

  end if;

  x_players_tbl := l_players_tbl;

  log('END', l_scope);

  exception
    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end possible_player_match;





------------------------------------------------------------------------------
------------------------------------------------------------------------------
/**
 * PRIVATE
 * Given a tournament ID and Tournament Session ID make sure we're closing the
 * the correct week
 *  1. Must be current tournament
 *  2. Must be the current session
 *  3. Rooms must have been defined and open
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created February 23, 2023
 * @param p_tournament_id
 * @param p_tournament_session_id
 * @return
 */
procedure validate_tournament_state (
    p_tournament_id         in wmg_tournaments.id%type
  , p_tournament_session_id in wmg_tournament_sessions.id%type
)
is
  l_scope  scope_t := gc_scope_prefix || 'validate_tournament_state';

  l_id wmg_tournaments.id%type;
begin
  -- logger.append_param(l_params, 'p_tournament_id', p_tournament_id);
  -- logger.append_param(l_params, 'p_tournament_session_id', p_tournament_session_id);
  log('BEGIN', l_scope);

  if g_must_be_current then -- make sure it's the current tournament. Only false for historical loads
    begin
       -- is the tournament really the current tournament?
       select id
         into l_id
         from wmg_tournaments
        where id = p_tournament_id
          and current_flag = 'Y';
    exception
      when no_data_found then
        raise_application_error(e_not_current_tournament, 'Tournament (id ' || p_tournament_id || ') is not the current tournament');
    end;
  end if;
       
  begin
     -- is the tournament session correct and part of the current tournament
     select id
       into l_id
       from wmg_tournament_sessions
      where tournament_id = p_tournament_id
        and id = p_tournament_session_id;
  exception
    when no_data_found then
      raise_application_error(e_not_correct_session, 'That tournament session is not correct (id ' || p_tournament_session_id || '). Not the current session or not the correct tournament');
  end;

  log('END', l_scope);

end validate_tournament_state;






/**
 * PRIVATE
 * Given a tournament ID and Tournament Session ID 
 * Snapshot the points for each player
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created February 23, 2023
 * @param p_tournament_id
 * @param p_tournament_session_id
 * @return
 */
procedure snapshot_points (
    p_tournament_id         in wmg_tournaments.id%type
  , p_tournament_session_id in wmg_tournament_sessions.id%type
)
is
  l_scope  scope_t := gc_scope_prefix || 'snapshot_points';

begin
  -- logger.append_param(l_params, 'p_tournament_id', p_tournament_id);
  -- logger.append_param(l_params, 'p_tournament_session_id', p_tournament_session_id);
  log('BEGIN', l_scope);

  merge into wmg_tournament_players tp
  using (
    select p.tournament_session_id
         , p.player_id
         , p.points
         , p.total_score
      from wmg_tournament_session_points_v p
     where p.tournament_session_id = p_tournament_session_id
  ) p
  on (
        p.tournament_session_id = tp.tournament_session_id
    and p.player_id = tp.player_id
  )
  when matched then
    update
       set tp.points = nvl(tp.points_override, p.points)  -- if there's a points override, keep it.
         , tp.total_score = p.total_score;
  
  log(SQL%ROWCOUNT || ' rows updated.', l_scope);

  log('END', l_scope);

end snapshot_points;






/**
 * PRIVATE
 * Given a tournament ID and Tournament Session ID 
 * Snapshot the System calculated badges for each player
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created April 16, 2023
 * @param p_tournament_id
 * @param p_tournament_session_id
 * @return
 */
procedure snapshot_badges (
    p_tournament_id         in wmg_tournaments.id%type
  , p_tournament_session_id in wmg_tournament_sessions.id%type
)
is
  l_scope  scope_t := gc_scope_prefix || 'snapshot_badges';

begin
  -- logger.append_param(l_params, 'p_tournament_id', p_tournament_id);
  -- logger.append_param(l_params, 'p_tournament_session_id', p_tournament_session_id);
  log('BEGIN', l_scope);

  log('.. Top 10 and 25 player badges');
  insert into wmg_player_badges (
      tournament_session_id
    , player_id
    , badge_type_code
    , badge_count
  )
  select p.tournament_session_id
       , p.player_id
       , case 
           when p.pos = 1 then 'FIRST'
           when p.pos = 2 then 'SECOND'
           when p.pos = 3 then 'THIRD'
           when p.pos >= 4 and  p.pos <= 10 then 'TOP10'
           when p.pos > 10 and  p.pos <= 25 then 'TOP25'
         end
       , 1
    from wmg_tournament_session_points_v p
   where p.tournament_session_id = p_tournament_session_id
     and p.pos <=25;


  insert into wmg_player_badges (
      tournament_session_id
    , player_id
    , badge_type_code
    , badge_count
  )
  with coconut as (
    select u.week
         , u.player_id, sum(case when par <= 0 then 1 else 0 end) under_par
         , sum(case when score = 1 then 1 else 0 end) hn1_count
      from wmg_rounds_unpivot_mv u
         , wmg_tournament_sessions ts
         , wmg_tournament_players tp
     where ts.week = u.week
       and ts.id = tp.tournament_session_id
       and tp.player_id = u.player_id
       and tp.issue_code is null  -- only players with no issues are eligible
       and ts.id = p_tournament_session_id
     having sum(case when par <= 0 and score is not null then 1 else 0 end) = 36
     group by u.week, u.player_id
  )
  , cactus as (
     select player_id, count(*) n
      from (
      select u.course_id || ':' || u.h h, u.score, any_value(u.player_id) player_id
        from wmg_rounds_unpivot_mv u
           , wmg_tournament_sessions ts
           , wmg_tournament_players tp
       where ts.id = tp.tournament_session_id
         and ts.week = u.week
         and tp.player_id = u.player_id
         and tp.issue_code is null  -- only players with no issues are eligible
         and ts.id = p_tournament_session_id
         and u.score = 1
      having count(*) = 1
       group by u.course_id || ':' || u.h, u.score
     )
     group by player_id
  )
  , duck as (
       select player_id, count(*) n
        from (
            select u.course_id || ':' || u.h h, u.score, u.player_id player_id
              from wmg_rounds_unpivot_mv u
                 , wmg_tournament_players tp
                 , wmg_tournament_sessions ts
             where ts.week = u.week
               and ts.id = tp.tournament_session_id
               and tp.player_id = u.player_id
               and tp.issue_code is null  -- only players with no issues are eligible
               and ts.id = p_tournament_session_id
               and u.score = 1
               and (u.course_id, u.h) in (
                     select u2.course_id, u2.h
                        -- , count(*) possible_ducks
                       from wmg_rounds_unpivot_mv u2
                          , wmg_tournament_sessions ts2
                          , wmg_tournament_players tp2
                      where ts2.week = u2.week
                        and ts2.id = tp2.tournament_session_id
                        and u2.player_id = tp2.player_id
                        and tp2.issue_code is null  -- only players with no issues are eligible
                        and ts2.id = p_tournament_session_id
                        and u2.score = 1 -- ace score
                        having count(*) between 2 and 2 
                        group by u2.course_id, u2.h
               )
       )
       group by player_id
  )
  , beetle as (
     select u.player_id, count(*) n
       from wmg_rounds_unpivot_mv u
          , wmg_tournament_players tp
          , wmg_tournament_sessions ts
      where ts.week = u.week
        and ts.id = tp.tournament_session_id
        and tp.player_id = u.player_id
        and tp.issue_code is null  -- only players with no issues are eligible
        and ts.id = p_tournament_session_id
        and (u.course_id, u.h, u.score) in (
          select u2.course_id, u2.h, u2.score
            from wmg_rounds_unpivot_mv u2
               , wmg_tournament_sessions ts2
           where ts2.week = u2.week
             and ts2.id = p_tournament_session_id
             and (u2.course_id, u2.h, u2.score) in (
                 select u3.course_id, u3.h, min(u3.score) possible_beetles
                   from wmg_rounds_unpivot_mv u3
                      , wmg_tournament_sessions ts3
                  where ts3.week = u3.week
                    and ts3.id = p_tournament_session_id
                    and u3.score > 1 -- non-ace score
                  group by u3.course_id, u3.h
           )
          having count(*) <= 3  -- only when less than 3 people got it
           group by u2.course_id, u2.h, u2.score
      )
     group by u.player_id
  )
  , diamond as (
    select u.player_id, count(*) aces
          from wmg_rounds_unpivot_mv u
             , wmg_tournament_players tp
             , wmg_tournament_sessions ts
         where ts.week = u.week
           and ts.id = tp.tournament_session_id
           and tp.player_id = u.player_id
           and tp.issue_code is null  -- only players with no issues are eligible
           and ts.completed_ind = 'N' -- only live results
           and ts.id = p_tournament_session_id
           and u.score = 1
         group by u.player_id
         having count(*) in (
             select max(sum(u2.score)) aces
              from wmg_rounds_unpivot_mv u2
                 , wmg_tournament_sessions ts2
              where ts2.week = u2.week
                and u2.score = 1
                and ts2.id = p_tournament_session_id
              group by u2.player_id
         )
  )
  select p.tournament_session_id
       , p.player_id
       , 'COCONUT' badge
       , 1 badge_count
    from wmg_tournament_session_points_v p
       , coconut
   where p.tournament_session_id = p_tournament_session_id
     and p.player_id = coconut.player_id
  union all
  select p.tournament_session_id
       , p.player_id
       , 'CACTUS' badge
       , cactus.n badge_count
    from wmg_tournament_session_points_v p
       , cactus
   where p.tournament_session_id = p_tournament_session_id
     and p.player_id = cactus.player_id
  union all
  select p.tournament_session_id
       , p.player_id
       , 'DUCK' badge
       , duck.n badge_count
    from wmg_tournament_session_points_v p
       , duck
   where p.tournament_session_id = p_tournament_session_id
     and p.player_id = duck.player_id
  union all
  select p.tournament_session_id
       , p.player_id
       , 'BEETLE' badge
       , beetle.n badge_count
    from wmg_tournament_session_points_v p
       , beetle
   where p.tournament_session_id = p_tournament_session_id
     and p.player_id = beetle.player_id
  union all
  select p.tournament_session_id
       , p.player_id
       , 'DIAMOND' badge
       , 1 badge_count
    from wmg_tournament_session_points_v p
       , diamond
   where p.tournament_session_id = p_tournament_session_id
     and p.player_id = diamond.player_id;
  
  log(SQL%ROWCOUNT || ' rows updated.', l_scope);

  log('END', l_scope);

end snapshot_badges;







/**
 * PRIVATE
 * Given a tournament ID and Tournament Session ID 
 * Discard the lowest points fom each player
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created February 23, 2023
 * @param p_tournament_id
 * @param p_tournament_session_id
 * @return
 */
procedure discard_points (
    p_tournament_id         in wmg_tournaments.id%type
  , p_tournament_session_id in wmg_tournament_sessions.id%type
)
is
  l_scope  scope_t := gc_scope_prefix || 'discard_points';

begin
  -- logger.append_param(l_params, 'p_tournament_id', p_tournament_id);
  -- logger.append_param(l_params, 'p_tournament_session_id', p_tournament_session_id);
  log('BEGIN', l_scope);

  log('.. restore previously discarded session', l_scope);
  update wmg_tournament_players
     set discarded_points_flag = null
   where id in (
      with curr_tournament as (
        select id
          from wmg_tournaments
         where id = p_tournament_id
      )
      , discard as (
        select floor( count(*)/3 ) drop_count
             , count(*) total_sessions
          from wmg_tournament_sessions ts
             , curr_tournament
         where ts.tournament_id = curr_tournament.id
         and ts.registration_closed_flag = 'Y'
      )
      select tournament_player_id
      from (
          select p.id tournament_player_id
               , p.player_id
               , p.points
               , p.discarded_points_flag
               , ts.tournament_id
               , ts.round_num
               , ts.week
               , ts.session_date
      --         , sum(case when p.discarded_points_flag = 'Y' then 0 else p.points end) season_total
               , row_number() over (partition by p.player_id order by p.points nulls first, ts.session_date) discard_order
               -- $IF env.kwt $THEN
               -- , row_number() over (partition by p.player_id order by sp.total_score desc nulls last, ts.session_date) discard_order
               , count(*) over (partition by p.player_id) sessions_played
          from wmg_tournament_sessions ts
             , wmg_tournament_players p
             , curr_tournament
          where ts.id = p.tournament_session_id
            and ts.tournament_id = curr_tournament.id
          -- and p.player_id in ( 22, 24, 26)
          order by p.player_id, ts.session_date
      )
       , discard
       -- (total_sessions - sessions_played) is needed in case they did not participate in all sessions
       where (total_sessions >= sessions_played and discard_order > (discard.drop_count - (total_sessions - sessions_played)))
    )
   and discarded_points_flag = 'Y';
  log(SQL%ROWCOUNT || ' rows updated.', l_scope);

  log('.. Discarding session', l_scope);

  update wmg_tournament_players
     set discarded_points_flag = 'Y' 
   where id in (
      with curr_tournament as (
        select id
          from wmg_tournaments
         where id = p_tournament_id
      )
      , discard as (
        select floor( count(*)/3 ) drop_count
             , count(*) total_sessions
          from wmg_tournament_sessions ts
             , curr_tournament
         where ts.tournament_id = curr_tournament.id
         and ts.registration_closed_flag = 'Y'
      )
      select tournament_player_id
      from (
          select p.id tournament_player_id
               , p.player_id
               , p.points
               , p.discarded_points_flag
               , ts.tournament_id
               , ts.round_num
               , ts.week
               , ts.session_date
      --         , sum(case when p.discarded_points_flag = 'Y' then 0 else p.points end) season_total
               , row_number() over (partition by p.player_id order by p.points nulls first, ts.session_date) discard_order
               , count(*) over (partition by p.player_id) sessions_played
          from wmg_tournament_sessions ts
             , wmg_tournament_players p
             , curr_tournament
          where ts.id = p.tournament_session_id
            and ts.tournament_id = curr_tournament.id
          -- and p.player_id in ( 22, 24, 26)
          order by p.player_id, ts.session_date
      )
       , discard
       -- (total_sessions - sessions_played) is needed in case they did not participate in all sessions
       where (total_sessions >= sessions_played and discard_order <= (discard.drop_count - (total_sessions - sessions_played)))
    );
  
  log(SQL%ROWCOUNT || ' rows updated.', l_scope);

  log('.. Un-Discard penalty points', l_scope);
  -- Negative points, -1 will always be sticky and cannot be discarded
  -- find discarded negative numbers and bring them back

  update wmg_tournament_players
     set discarded_points_flag = null
   where id in (
      with curr_tournament as (
        select id
          from wmg_tournaments
         where id = p_tournament_id
      )
      select p.id tournament_player_id
          from wmg_tournament_sessions ts
             , wmg_tournament_players p
             , curr_tournament
          where ts.id = p.tournament_session_id
            and ts.tournament_id = curr_tournament.id
            and p.points < 0  -- find discarded negative numbers and bring them back
            and p.discarded_points_flag = 'Y'
    );

  log('END', l_scope);

end discard_points;




/**
 * PRIVATE
 * Given a tournament ID and Tournament Session ID 
 * Promote players to their new status: Ama, Semi, Pro
 *
 * Guideline:
 *
 *    PRO status can be achieved by the following:
 *    (1x) Top 5 -or- (3x) Top 10 
 *
 *    Players with 85 season points or more retained PRO status from Season 8
 *
 *    SEMI-PRO status can be achieved by the following:
 *    (1x) Top 15  -or- (3x) Top 20 with 9 pts.
 *
 **
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created February 23, 2023
 * @param p_tournament_id
 * @param p_tournament_session_id
 * @return
 */
procedure promote_players (
    p_tournament_id         in wmg_tournaments.id%type
  , p_tournament_session_id in wmg_tournament_sessions.id%type
)
is
  l_scope  scope_t := gc_scope_prefix || 'promote_players';

begin
  -- logger.append_param(l_params, 'p_tournament_id', p_tournament_id);
  -- logger.append_param(l_params, 'p_tournament_session_id', p_tournament_session_id);
  log('BEGIN', l_scope);

  log('.. Advance all players that played from NEW to Amateur', l_scope);
  update wmg_players
     set rank_code = 'AMA'
   where id in (
    select p.player_id
      from wmg_tournament_session_points_v p
     where p.tournament_session_id = p_tournament_session_id
       and p.points > 0  -- new players that actually played
       and p.rank_code = 'NEW'
   );
  
  log(SQL%ROWCOUNT || ' rows updated.', l_scope);


  /*
   *    SEMI-PRO status can be achieved by the following:
   *    (1x) Top 25  -or- .. TBD
   */

  log('.. Advance to SEMI', l_scope);
  update wmg_players
     set rank_code = 'SEMI'
   where id in (
    select p.player_id
      from wmg_tournament_session_points_v p
     where p.tournament_session_id = p_tournament_session_id
       and p.pos <= 25
       and p.rank_code not in ('PRO', 'SEMI', 'ELITE')
   );

  /*
   *    PRO status can be achieved by the following:
   *    (1x) Top 10  -or- TBD
   */

  log('.. Advance to PRO', l_scope);
  update wmg_players
     set rank_code = 'PRO'
   where id in (
    select p.player_id
      from wmg_tournament_session_points_v p
     where p.tournament_session_id = p_tournament_session_id
       and p.pos <= 10
       and p.rank_code not in ('PRO', 'ELITE')
   );
  
  log(SQL%ROWCOUNT || ' rows updated.', l_scope);



  /*
   *    ELITE status can be achieved by the following:
   *    (1x) Top 3 -or- TBD
   */

  log('.. Advance to ELITE', l_scope);
  update wmg_players
     set rank_code = 'ELITE'
   where id in (
    select p.player_id
      from wmg_tournament_session_points_v p
     where p.tournament_session_id = p_tournament_session_id
       and p.pos <= 3
       and p.rank_code != 'ELITE'
   );
  
  log(SQL%ROWCOUNT || ' rows updated.', l_scope);



  log('END', l_scope);

end promote_players;





/**
 * Up to the given tournament_session, find the new unicorns
 * Unicorn: Something rare and unique. In this case a unicorn is a 
 * unique Hole in One made after 5 times a tournament was played
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created August 31, 2023
 * @param x_result_status
 * @return
 */
procedure add_unicorns(
    p_tournament_session_id in wmg_tournament_sessions.id%type
)
is
  l_scope  scope_t := gc_scope_prefix || 'add_unicorns';
  l_attempts number;
begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  log('BEGIN', l_scope);

  for u in (
  with course_play_count as (
        select c.course_id, count(*) play_count, max(s.week) week, max(s.session_date) session_date
        from wmg_tournament_courses c
           , wmg_tournament_sessions s
        where s.id = c.tournament_session_id
          and c.course_id in (select course_id from wmg_tournament_courses where tournament_session_id = p_tournament_session_id)
          and s.completed_ind = 'Y'
        group by c.course_id
  )
  , courses_played as (
      select c.course_id, c.name course_name, cc.play_count, cc.week, cc.session_date
      from wmg_courses_v  c
         , course_play_count cc
      where c.course_id = cc.course_id
        and cc.play_count >= 5  -- filter qualifying courses. 5 x or more
  )
  select uni.course_name
       , uni.course_id
       , uni.play_count
       , uni.h
       , uni.week
       , (select u.player_id
        from wmg_rounds_unpivot_mv u
       where u.course_id = uni.course_id
         and u.h = uni.h
         and u.week <= uni.week
         and u.player_id != 0 -- skip system records
         and u.score = 1) ace_by_player_id
      /*
        -- for debuging
       , (select listagg(u.week || ' - ' || p.player_name, ',') player_name
        from wmg_rounds_unpivot_mv u
           , wmg_players_v p
       where u.player_id = p.id
         and u.course_id = uni.course_id
         and u.h = uni.h
         and u.week <= uni.week
         and u.score = 1) ace_by
        */
  from (
      select u.course_id, cp.course_name, cp.play_count, u.h
           , max(u.week) week
        from wmg_rounds_unpivot_mv u
           , courses_played cp
        where u.score = 1
          and u.course_id = cp.course_id
          and u.player_id != 0 -- skip system records
          and cp.play_count >= 5
          and u.week in (select ts.week from wmg_tournament_sessions ts where ts.session_date <= cp.session_date)
          and (u.course_id, u.h) not in (select course_id, h from wmg_player_unicorns) -- eliminate previous unicorns
        group by u.course_id, cp.course_name, cp.play_count, u.h
       having count(*) = 1
  ) uni
  order by uni.course_name, uni.h
  )
  loop

    -- count the number of attempts at the hole before the unicorn
    select count(*) attempts
      into l_attempts
     from wmg_rounds_unpivot_mv a
     where a.course_id = u.course_id
       and a.h = u.h
       and a.week in (
          select ts.week                       -- collect all the weeks before the unicorn and including
            from wmg_tournament_sessions ts 
           where ts.session_date <= (          -- get all the sessions before that
             select wts.session_date           -- date the unicorn was achived
               from wmg_tournament_sessions wts 
              where wts.week = u.week
           )
         );

    insert into wmg_player_unicorns (
       course_id
     , player_id
     , h
     , attempt_count
     , score_tournament_session_id
     , award_tournament_session_id
    )
    select u.course_id
       , u.ace_by_player_id
       , u.h
       , l_attempts
       , ts.id                    score_tournament_session_id
       , p_tournament_session_id  award_tournament_session_id
     from wmg_tournament_sessions ts
     where ts.week = u.week;

    log('.. Added ' || SQL%ROWCOUNT, l_scope);
  end loop;


  log('.. Updating repeat unicorns, ie commoncorns', l_scope);
  for courses in (
    with course_play_count as (
          select c.course_id, count(*) play_count, max(s.week) week, max(s.session_date) session_date
          from wmg_tournament_courses c
             , wmg_tournament_sessions s
          where s.id = c.tournament_session_id
            and s.session_date <= (select ts.session_date from wmg_tournament_sessions ts where ts.id = p_tournament_session_id)
            and c.course_id in (
              select c.course_id
                from wmg_tournament_sessions ts
                   , wmg_tournament_courses c
                 where ts.id = c.tournament_session_id 
                   and ts.id = p_tournament_session_id
                )
          group by c.course_id
    )
    , courses_played as (
        select c.course_id, c.name course_name, cc.play_count, cc.week, cc.session_date
        from wmg_courses_v  c
           , course_play_count cc
        where c.course_id = cc.course_id
          and cc.play_count >= 5
    )
    select course_id
      from courses_played
  )
  loop
    -- for each course and for each hole, update the number of 
    -- unicorn repeats
    update wmg_player_unicorns pu
    set pu.repeat_count = (
       select case when n = 1 then null else n -1 end
         from (
          select count(*) n
          from wmg_rounds_unpivot_mv u
             , wmg_players_v p
          where u.player_id = p.id
            and u.course_id = pu.course_id
            and u.h = pu.h
            and u.score = 1
      )
    )
    where pu.course_id = courses.course_id;
    
  end loop;


  log('END', l_scope);

  exception
    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end add_unicorns;







/**
 * After the tournament is closed add people's best scores to the leaderboards
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created June 29, 2024
 * @param p_tournament_session_id
 * @return
 */
procedure add_leaderboard_entries(
    p_tournament_session_id in wmg_tournament_sessions.id%type
)
is
  l_scope  scope_t := gc_scope_prefix || 'add_leaderboard_entries';

  l_leader_rec wmg_leaderboard_util.leader_rec_t;

  procedure init_record
  as
  begin
    -- reset for next record
    l_leader_rec := null;

    l_leader_rec.rec_type := wmg_leaderboard_util.c_type_standard;
    l_leader_rec.tournament_flag := 'Y';
    l_leader_rec.approved_flag := 'Y';
    l_leader_rec.approved_on   := current_timestamp;
    l_leader_rec.approved_by   := 'SYSTEM';
  end init_record;

begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  log('BEGIN', l_scope);

  select id
    into l_leader_rec.guild_id
    from wmg_guilds
   where code = 'CLASSIC';

  for e in (
    select p.player_id
         , p.easy_course_id
         , p.easy_round_id
         , p.easy
         , p.hard_course_id
         , p.hard
         , p.hard_round_id
      from wmg_tournament_session_points_v p
     where p.tournament_session_id = p_tournament_session_id
  )
  loop

    init_record;
    -- Adding Easy Scores
    l_leader_rec.player_id := e.player_id;
    l_leader_rec.course_id := e.easy_course_id;
    l_leader_rec.score := e.easy;
    l_leader_rec.round_id := e.easy_round_id;

    wmg_leaderboard_util.add_standard_entry(p_leader_rec => l_leader_rec);

    -- Adding Hard Scores
    if e.hard is not null then
      init_record;
      l_leader_rec.player_id := e.player_id;
      l_leader_rec.course_id := e.hard_course_id;
      l_leader_rec.score := e.hard;
      l_leader_rec.round_id := e.hard_round_id;

      wmg_leaderboard_util.add_standard_entry(p_leader_rec => l_leader_rec);
    end if;

  end loop;


  log('END', l_scope);


  exception
    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end add_leaderboard_entries;




$IF env.kwt $THEN
/**
 * After the tournament is closed add people's best scores to the Montly
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created September 8, 2024
 * @param p_tournament_session_id
 * @return
 */
procedure add_monthly_entries(
    p_tournament_session_id in wmg_tournament_sessions.id%type
)
is
  l_scope  scope_t := gc_scope_prefix || 'add_monthly_entries';

  l_m_score kw_monthly_results.score%type;
  l_m_hn1 kw_monthly_results.hn1%type;
  l_kwt_hn1 number;

  add_kwt_score boolean;  -- determine if the scores needs to be added to the Monthly

begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  log('BEGIN', l_scope);

  -- loop though the courses for the current KWT week and match them to the monthly courses
  -- if the courses match, we will process those
  <<current_monthly>>
  for curr_monthly in (
    select mm.id monthly_id
         , mc.course_id
         , mc.course_mode
      from kw_monthly_courses_v mc
      join kw_monthly_months mm on mm.id = mc.monthly_id
      join wmg_tournament_sessions_v ts on (mc.course_id = ts.easy_course_id or mc.course_id = ts.hard_course_id)
    where mm.current_flag = 'Y'
      and ts.tournament_session_id = p_tournament_session_id
  )
  loop

    log('.. monthly_id:' || curr_monthly.monthly_id, l_scope);
    log('.. course_id :' || curr_monthly.course_id, l_scope);

    -- we have montly courses that match the KWT weekly, see whcih scores are better
    <<kwt_player_scores>>
    for kwt_scores in (
      select p.player_id
           , p.easy_course_id course_id
           , p.easy_round_id  round_id
           , p.easy           score
           , p.week
        from wmg_tournament_session_points_v p
       where p.tournament_session_id = p_tournament_session_id
         and curr_monthly.course_mode = 'E'
       union all
      select p.player_id
           , p.hard_course_id course_id
           , p.hard_round_id  round_id
           , p.hard           score
           , p.week
        from wmg_tournament_session_points_v p
       where p.tournament_session_id = p_tournament_session_id
         and curr_monthly.course_mode = 'H'
    )
    loop
      add_kwt_score := false;  -- new player, we don't know if we're adding
      l_kwt_hn1 := 0;          -- reset aces

      begin
        -- find the current montly score for the player
        select mr.score
             , mr.hn1
         into l_m_score
            , l_m_hn1
         from kw_monthly_courses mc
            , kw_monthly_players mp
            , kw_monthly_results mr
        where mc.monthly_id = mp.monthly_id
          and mc.monthly_id = curr_monthly.monthly_id
          and mc.course_id =  kwt_scores.course_id
          and mp.player_id =  kwt_scores.player_id
          and mr.m_course_id = mc.id  -- m_course_id
          and mr.m_player_id = mp.id; -- m_player_id
      exception
        when no_data_found then
           -- they don't have one that's an automatic add
           add_kwt_score := true;
           l_m_score := null;
           l_m_hn1 := null;
      end;

      if add_kwt_score or l_m_score >= kwt_scores.score then 
        -- if we're adding or the new score better or equal, get the KWT hn1
        select count(*)
          into l_kwt_hn1
          from wmg_rounds_unpivot_mv u
         where u.week = kwt_scores.week
           and u.player_id = kwt_scores.player_id
           and u.course_id = kwt_scores.course_id
           and u.score = 1;
      end if;


      -- decide if we're adding
      if add_kwt_score  -- automatic add
       or (l_m_score = kwt_scores.score and l_kwt_hn1 > l_m_hn1) -- same score, but improved aces
       or (l_m_score > kwt_scores.score)   -- monthly is worse than KWT
      then 
        -- the current KWT is better than the Montly
        log('..        player_id:' || kwt_scores.player_id, l_scope);
        log('..        l_m_score:' || l_m_score, l_scope);
        log('..          l_m_hn1:' || l_m_hn1, l_scope);
        log('.. kwt_scores.score:' || kwt_scores.score, l_scope);
        log('.. kwt_scores.hn1  :' || l_kwt_hn1, l_scope);


        merge into kw_monthly_results mr
        using (
            select mc.id as m_course_id
                 , mp.id as m_player_id
                 , kwt_scores.score as score
                 , l_kwt_hn1 as hn1
             from kw_monthly_courses mc
                , kw_monthly_players mp
            where mc.monthly_id = mp.monthly_id
              and mc.monthly_id = curr_monthly.monthly_id
              and mc.course_id  = curr_monthly.course_id
              and mp.player_id  = kwt_scores.player_id
        ) src
        on (mr.m_course_id = src.m_course_id and mr.m_player_id = src.m_player_id)
        when matched then
            update set mr.score = src.score
                     , mr.hn1 = src.hn1
        when not matched then
            insert (m_course_id, m_player_id, score, hn1)
            values (src.m_course_id, src.m_player_id, src.score, src.hn1);

      end if; -- adding score

    end loop kwt_player_scores;

  end loop current_monthly;

  log('END', l_scope);


  exception
    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end add_monthly_entries;
$END





/**
 * Given a tournament ID perform the necessary steps to close the week
 *  1. Validate the tournamet and session are correct
 *  2. Calculate points and assign to each player
 *  3. Flag Points to discard
 *  4. Set session as completed
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created February 20, 2023
 * @param p_tournament_id
 * @param p_tournament_session_id
 * @return
 */
procedure close_tournament_session (
    p_tournament_id         in wmg_tournaments.id%type
  , p_tournament_session_id in wmg_tournament_sessions.id%type
)
is
  l_scope  scope_t := gc_scope_prefix || 'close_tournament_session';
begin
  -- logger.append_param(l_params, 'p_tournament_id', p_tournament_id);
  -- logger.append_param(l_params, 'p_tournament_session_id', p_tournament_session_id);
  log('BEGIN', l_scope);

  log('.. validations', l_scope);
  validate_tournament_state(
      p_tournament_id => p_tournament_id
    , p_tournament_session_id => p_tournament_session_id
  );


  log('.. snaptshot points', l_scope);
  snapshot_points(
      p_tournament_id         => p_tournament_id
    , p_tournament_session_id => p_tournament_session_id
  );

  log('.. discarding points', l_scope);
  discard_points(
      p_tournament_id         => p_tournament_id
    , p_tournament_session_id => p_tournament_session_id
  );

  log('.. Add Badges', l_scope);
  snapshot_badges(
      p_tournament_id         => p_tournament_id
    , p_tournament_session_id => p_tournament_session_id
  );

  if env.wmgt then
    if g_must_be_current then -- make sure it's the current tournament. Only false for historical loads
      log('.. promote players', l_scope);
      promote_players(
          p_tournament_id         => p_tournament_id
        , p_tournament_session_id => p_tournament_session_id
      );
    end if;
  end if;

  log('.. close tournament session', l_scope);
  update wmg_tournament_sessions ts
     set ts.completed_ind = 'Y'
       , ts.completed_on = current_timestamp
   where ts.id = p_tournament_session_id
     and ts.tournament_id = p_tournament_id;

  commit;

  log('.. Add Unicorns', l_scope);
  -- unicorns depend on the session being completed!
  add_unicorns(
     p_tournament_session_id => p_tournament_session_id
  );

  commit;

  if env.wmgt then
    add_leaderboard_entries(
      p_tournament_session_id => p_tournament_session_id
    );
  end if;

  $IF env.kwt $THEN
    add_monthly_entries(
      p_tournament_session_id => p_tournament_session_id
    );
  $END


  wmg_notification.notify_channel_tournament_close(
     p_tournament_session_id => p_tournament_session_id
  );

  log('END', l_scope);

  exception
    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end close_tournament_session;



/**
 * Detect when a sesson is over.
 *  * If we have a p_tournament_session_id then we're actively in a season
 *  * Or if the very las round is round 12 and it's completed
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created February 5, 2024
 * @param p_tournament_session_id
 * @return boolean
 */
function is_season_over(
   p_tournament_session_id in wmg_tournament_sessions.id%type
)
return boolean
is
  $IF $$LOGGER $THEN
  l_scope  logger_logs.scope%type := gc_scope_prefix || 'is_season_over';
  l_params logger.tab_param;
  $END

  l_tournament_session_id wmg_tournament_sessions.id%type;
  l_round_num wmg_tournament_sessions.round_num%type;
  l_completed_ind wmg_tournament_sessions.completed_ind%type;

begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  -- logger.log('BEGIN', l_scope, null, l_params);


  if nvl(p_tournament_session_id,-1) != -1 then
    return false;
  end if;

  select id, round_num, completed_ind
    into l_tournament_session_id, l_round_num, l_completed_ind
    from wmg_tournament_sessions
   where week not like '%B%'  -- skip the special inbetween tournaments
   order by session_date desc
   fetch first 1 rows only;

  if l_round_num = 12 and l_completed_ind = 'Y' then
    return true;
  end if;

  return false;

  -- logger.log('END', l_scope, null, l_params);

  exception
    when no_data_found then
      -- no real previous season
      return false;

    when OTHERS then
      $IF $$LOGGER $THEN
      logger.log_error('Unhandled Exception', l_scope, null, l_params);
      $END
      -- x_result_status := mm_api.g_ret_sts_unexp_error;
      raise;
end is_season_over;





/**
 * Given a finishing rank, calculate the score the player will receive
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created 
 * @param p_rank         rank the player finished
 * @param p_percent_rank player percent rank (the top 10 do NOT use percent rank)
 * @param p_player_count players in the field
 * @return
 */
function score_points(
    p_rank         in number
  , p_percent_rank in number
  , p_player_count in number
)
return number
is
  l_scope  scope_t := gc_scope_prefix || 'score_points';
  -- l_params logger.tab_param;
begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  -- log('BEGIN', l_scope);

  if p_rank <= 10 then
    return 
      case p_rank
      when  1 then 25
      when  2 then 21 
      when  3 then 18 
      when  4 then 16 
      when  5 then 15 
      when  6 then 14 
      when  7 then 13 
      when  8 then 12 
      when  9 then 11 
      when 10 then 10
      end;
  else
    if p_player_count < 21 then
     return 20 - p_rank;
    elsif p_percent_rank <= 0.111 then
      return 9;
    elsif p_percent_rank <= 0.222 then
      return 8;
    elsif p_percent_rank <= 0.333 then
      return 7;
    elsif p_percent_rank <= 0.444 then
      return 6;
    elsif p_percent_rank <= 0.555 then
      return 5;
    elsif p_percent_rank <= 0.666 then
      return 4;
    elsif p_percent_rank <= 0.777 then
      return 3;
    elsif p_percent_rank <= 0.888 then
      return 2;
    else
      return 1;
    end if;
  end if;


  -- log('END', l_scope);

exception
  when OTHERS then
    log('Unhandled Exception', l_scope);
    raise;
end score_points;




/**
 * Process a player registration. Either Signup or Unregister by specifying
 * the correct p_action parameter.
 * Unregistering does not delete the record, instead the active_ind is set to N
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created August 18, 2025
 * @param p_tournament_session_id
 * @param p_player_id
 * @param p_action SIGNUP | UNREGISTER
 * @param p_time_slot OPTIONAL
 * @return
 */
procedure process_registration(
    p_tournament_session_id in wmg_tournament_players.tournament_session_id%type
  , p_player_id   in wmg_tournament_players.player_id%type
  , p_action      in varchar2
  , p_time_slot   in wmg_tournament_players.time_slot%type
)
is
  l_scope  logger_logs.scope%type := gc_scope_prefix || 'process_registration';
  l_params logger.tab_param;

  l_valid_time_slot integer;
  l_player_name wmg_players_v.player_name%type;
begin
  logger.append_param(l_params, 'p_tournament_session_id', p_tournament_session_id);
  logger.append_param(l_params, 'p_player_id', p_player_id);
  logger.append_param(l_params, 'p_action', p_action);
  logger.append_param(l_params, 'p_time_slot', p_time_slot);
  logger.log('BEGIN', l_scope, null, l_params);

  if p_action not in ('SIGNUP', 'UNREGISTER') then
    raise_application_error(-20002, 'Unknown action "' || p_action || '" expected SIGNUP or UNREGISTER');
  end if;

  if p_action = 'SIGNUP' then
    select count(*)
      into l_valid_time_slot
      from wmg_time_slots_all_v
     where time_slot = p_time_slot;

    if l_valid_time_slot = 0 then
      raise_application_error(-20003, 'Invalid time_slot "' || p_time_slot || '"');
    end if;
  end if;

  select player_name
    into l_player_name
    from wmg_players_v
   where id = p_player_id;

  merge into wmg_tournament_players p
   using (
     select p_tournament_session_id tournament_session_id
          , p_player_id player_id
          , decode(p_action, 'UNREGISTER', 'N', 'Y') active_ind
          , p_time_slot time_slot
       from dual
    ) np
   on (p.tournament_session_id = np.tournament_session_id
    and p.player_id = np.player_id
   )
  when matched then
    update
       set time_slot = nvl(np.time_slot, p.time_slot)
         , active_ind = np.active_ind
  when not matched then
    insert (
        tournament_session_id
      , player_id
      , time_slot
      , active_ind
    )
    values (
        np.tournament_session_id
      , np.player_id
      , np.time_slot
      , np.active_ind
    );

  log('.. ' || p_action || ' player ' || l_player_name || case when p_action = 'SIGNUP' then ' for ' else ' from ' end || p_time_slot, l_scope);

  logger.log('END', l_scope, null, l_params);

  exception
    when OTHERS then
      logger.log_error('Unhandled Exception', l_scope, null, l_params);
      raise;
end process_registration;







/**
 * Given a player keep track if their easy or hard score card is missing
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created February 20, 2023
 * @param p_player_id
 * @param p_course_id
 * @param p_remove
 * @return
 */
procedure score_entry_verification(
   p_week      in wmg_rounds.week%type
 , p_player_id in wmg_players.id%type
 , p_course_id in number default null
 , p_remove    in boolean default false
)
is
  l_scope  scope_t := gc_scope_prefix || 'score_entry_verification';

  l_course_rec  wmg_courses%rowtype;
begin
  -- logger.append_param(l_params, 'p_tournament_id', p_tournament_id);
  -- logger.append_param(l_params, 'p_tournament_session_id', p_tournament_session_id);
  log('BEGIN', l_scope);

  if p_course_id is not null then
    select *
      into l_course_rec
      from wmg_courses
     where id = p_course_id;
  end if;


  if p_remove then
    delete 
      from wmg_verification_queue 
     where week = p_week and (easy_player_id = p_player_id or hard_player_id = p_player_id);
  else

    merge into wmg_verification_queue q
    using (
      select r.week
           , r.players_id
           , r.course_id
           , l_course_rec.course_mode course_mode
        from wmg_rounds r
       where r.week = p_week
         and r.players_id = p_player_id
         and r.course_id = l_course_rec.id
    ) r
    on (
          q.week = r.week
      and (q.easy_player_id = r.players_id or q.hard_player_id = r.players_id)
    )
    when matched then
      update
         set q.easy_player_id = decode(r.course_mode, 'E', r.players_id, q.easy_player_id)
           , q.hard_player_id = decode(r.course_mode, 'H', r.players_id, q.hard_player_id)
    when not matched then
      insert (
          week
        , easy_player_id
        , hard_player_id
      )
      values (
          r.week
        , decode(r.course_mode, 'E', r.players_id, null)
        , decode(r.course_mode, 'H', r.players_id, null)
      );
  end if;  

  -- delete the finished entries
  delete from wmg_verification_queue
   where week = p_week
     and easy_player_id = p_player_id
    and hard_player_id = p_player_id;

  log('END', l_scope);

  exception
    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end score_entry_verification;





/**
 * Given a player action (noshow, noscore, vialoation), (S)et | (C)lear according 
 * to the operation
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created August 11, 2023
 * @param p_player_id
 * @param p_issue_code: NOSHOW, NOSCORE, INFRACTION
 * @param p_operation: (S)et | (C)lear
 * @return
 */
procedure set_verification_issue(
   p_player_id  in wmg_players.id%type
 , p_issue_code in varchar2 default null
 , p_operation  in varchar2 default null  -- (S)et | (C)lear
 , p_from_ajax  in boolean default true
)
is
  l_scope  scope_t := gc_scope_prefix || 'set_verification_issue';

  l_issue_code wmg_tournament_players.issue_code%type;
  l_issue_rec wmg_issues%rowtype;
  l_operation  varchar2(1);  -- (S)et | (C)lear
begin
  -- logger.append_param(l_params, 'p_player_id', p_player_id);
  -- logger.append_param(l_params, 'p_issue_code', p_issue_code);
  -- logger.append_param(l_params, 'p_operation', p_operation);
  log('BEGIN', l_scope);
  log('.. p_player_id:'  || p_player_id, l_scope);
  log('.. p_issue_code:' || p_issue_code, l_scope);
  log('.. p_operation:'  || p_operation, l_scope);

  if p_issue_code is null then
    l_issue_code := c_issue_noshow;  -- the default issue value
    l_operation := 'S';    -- if we had no value we're always setting
  else
    l_issue_code := p_issue_code;
    l_operation := p_operation;
  end if;

  log('.. l_issue_code:' || l_issue_code, l_scope);
  log('.. l_operation:' || l_operation, l_scope);

  select *
    into l_issue_rec
    from wmg_issues
   where code = l_issue_code;

  -- toggle the verification
  update wmg_tournament_players
   set issue_code = case
                      when l_operation = 'C' then null
                      else l_issue_code
                    end
     , verified_score_flag = case when l_operation = 'C' then null else 'Y' end
     , verified_by         = case when l_operation = 'C' then null else sys_context('APEX$SESSION','APP_USER') end
     , verified_on         = case when l_operation = 'C' then null else current_timestamp end
     , verified_note       = 
        case 
          when l_operation = 'C' then null 
          else l_issue_rec.description
        end
      , points_override = 
        case 
          when l_operation = 'C' then null 
          else l_issue_rec.tournament_points_override
        end
    where id = p_player_id;

  log('.. rows:' || SQL%ROWCOUNT, l_scope);

  if p_from_ajax then
    apex_json.open_object; -- {
      apex_json.write('success', true);
    apex_json.close_object; -- }
  end if;


  log('END', l_scope);

  exception
    when OTHERS then
      log('Unhandled Exception', l_scope);
      if p_from_ajax then
        apex_json.open_object; -- {
          apex_json.write('success', false);
          apex_json.write('error', sqlerrm);
        apex_json.close_object; -- }
      else
        raise;
      end if;
end set_verification_issue;





/**
 * Given a player verify the room if all the other players have been verified
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created August 13, 2023
 * @param p_tournament_player_id
 * @return
 */
procedure verify_players_room(
   p_tournament_player_id  in wmg_tournament_players.id%type
)
is
  l_scope  scope_t := gc_scope_prefix || 'verify_players_room';

  l_tournament_session_id wmg_tournament_sessions.id%type;
  l_verified_score_flag   wmg_tournament_rooms.verified_score_flag%type;
  l_time_slot wmg_tournament_rooms.time_slot%type;
  l_room_no   wmg_tournament_rooms.room_no%type;
begin
  -- logger.append_param(l_params, 'p_player_id', p_player_id);
  -- logger.append_param(l_params, 'p_issue_code', p_issue_code);
  -- logger.append_param(l_params, 'p_operation', p_operation);
  log('BEGIN', l_scope);
  log('.. p_tournament_player_id:'  || p_tournament_player_id, l_scope);

  <<room_status>>
  begin
    -- If all the rows match their verification then l_verified_score_flag will have the value
    -- usually Y
    -- But if there are too_many_rows, we see if there's at least one E(rror)
    select distinct tournament_session_id, verified_score_flag, time_slot, room_no
      into l_tournament_session_id, l_verified_score_flag, l_time_slot, l_room_no
    from wmg_tournament_players
    where (tournament_session_id, time_slot, room_no) in (
        select tournament_session_id, time_slot, room_no
          from wmg_tournament_players
         where id = p_tournament_player_id
    )
      and active_ind = 'Y';  -- include registered players only

  exception
  when TOO_MANY_ROWS then
    l_verified_score_flag := null;

    -- if there's at least one E on the room keep the room with an E
    select case when count(*) > 0 then 'E' else null end
      into l_verified_score_flag
      from wmg_tournament_players
      where (tournament_session_id, time_slot, room_no) in (
          select tournament_session_id, time_slot, room_no
            from wmg_tournament_players
           where id = p_tournament_player_id
      )
       and verified_score_flag = 'E';

  end room_status;

  update wmg_tournament_rooms
     set verified_score_flag = l_verified_score_flag
   where tournament_session_id = l_tournament_session_id
     and time_slot = l_time_slot
     and room_no = l_room_no;


  log('END', l_scope);

  exception
    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end verify_players_room;





/**
 * Given a tournament ID, Tournament session and Time Slot
 * close out the ability to enter scores by setting the "verified" flag on
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created August 6, 2023
 * @param p_tournament_id
 * @param p_tournament_session_id
 * @param p_time_slot
 * @return
 */
procedure close_time_slot_time_entry (
    p_tournament_session_id in wmg_tournament_sessions.id%type
  , p_time_slot             in wmg_tournament_players.time_slot%type
)
is
  l_scope  scope_t := gc_scope_prefix || 'close_time_slot_time_entry';
  l_issue_rec wmg_issues%rowtype;

begin
  -- logger.append_param(l_params, 'p_tournament_id', p_tournament_id);
  -- logger.append_param(l_params, 'p_tournament_session_id', p_tournament_session_id);
  log('BEGIN', l_scope);


  -- Send channel notifications of the people thay did not send a notification
  wmg_notification.notify_channel_about_players(
      p_tournament_session_id => p_tournament_session_id
    , p_time_slot => p_time_slot
  );


  begin
      select *
        into l_issue_rec
        from wmg_issues
       where code = c_issue_noscore;
  exception 
    -- protect against errors in case the issue is gone
    when no_data_found then
      l_issue_rec.code := c_issue_noscore;
      l_issue_rec.description := 'Scores not entered in time';
  end;

  log('.. loop throough pending time entries', l_scope);
  for p in (
    select p.week
         , p.player_id
         , p.tournament_player_id
         , p.player_name
         , p.time_slot
         , p.room_no
         , r.total_score
         , r.round_created_on
         , r.easy_scorecard
         , r.hard_scorecard
         , r.total_scorecard
         -- , r.round_created_on
         , p.verified_score_flag
         , p.verified_note
         , p.verified_by
         , p.verified_on
      from wmg_tournament_results_v r
         , wmg_tournament_player_v p
     where p.week = r.week (+)
       and p.player_id = r.player_id (+)
       and p.tournament_session_id = p_tournament_session_id
       and p.time_slot = p_time_slot
       and p.active_ind = 'Y'            -- still registed
       and p.verified_score_flag is null -- not verified yet
       and p.issue_code is null          -- no issues raised
       and r.total_scorecard is null     -- No scores entered
  )
  loop


    /*  WE DO NOT WANT SCORE AT THIS TIME
    -- if p.round_created_on is null then

      -- add empty rounds because there was no round created
      insert into wmg_rounds(week, course_id, players_id, room_name
         , override_score
         , override_reason
         , override_by
         , override_on
        )
      select p.week
           , c.course_id
           , p.player_id
           , 'WMGT' || p.room_no
           , 36 override_score
           , 'Scored not entered on time' override_reason
           , 'SYSTEM' override_by
           , current_timestamp override_on
        from wmg_tournament_courses c
       where c.tournament_session_id = p_tournament_session_id
       order by c.course_no;

    -- end if;
    */

    /*
        No automatic points yet
         , points = -1           -- this will make the -1 visual before the tournament closes
         , points_override = -1  -- this will maintain the -1 when the tournament closes
    */
    update wmg_tournament_players
       set verified_by = 'SYSTEM'
         , verified_on = current_timestamp
         , verified_note = l_issue_rec.description
         , verified_score_flag = 'Y'
         , issue_code = l_issue_rec.code
         , points_override = l_issue_rec.tournament_points_override
     where id = p.tournament_player_id;

    verify_players_room(p_tournament_player_id => p.tournament_player_id );

    commit;  -- just in case something fails

  end loop;

  log('END', l_scope);

  exception
    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end close_time_slot_time_entry;





/**
 * Create a Job `WMGT_CLOSE_SCORING` that will be called on-demand
 * at the time rooms are defined and open
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created August 6, 2023
 * @param x_result_status
 * @return
 */
procedure create_close_scoring_job(
    p_tournament_session_id in wmg_tournament_sessions.id%type
  , p_slot_number           in wmg_tournament_players.time_slot%type
  , p_time_slot             in wmg_tournament_players.time_slot%type
  , p_job_run               in timestamp with time zone
)
is
  l_scope  scope_t := gc_scope_prefix || 'create_close_scoring_job';

  l_job_name  varchar2(100);
begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  log('BEGIN', l_scope);

/*
PROCEDURE create_job(
  job_name                IN VARCHAR2,
  job_type                 IN VARCHAR2,
  job_action              IN VARCHAR2,
  number_of_arguments     IN PLS_INTEGER              DEFAULT 0,
  start_date              IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
  event_condition         IN VARCHAR2                 DEFAULT NULL,
  queue_spec              IN VARCHAR2,
  end_date                IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
  job_class               IN VARCHAR2              DEFAULT '$SCHED_DEFAULT$',
  enabled                 IN BOOLEAN                  DEFAULT FALSE,
  auto_drop               IN BOOLEAN                  DEFAULT TRUE,
  comments                IN VARCHAR2                 DEFAULT NULL,
  credential_name         IN VARCHAR2                 DEFAULT NULL,
  destination_name        IN VARCHAR2                 DEFAULT NULL);
*/

  l_job_name := 'WMGT_CLOSE_SCORING_' || p_tournament_session_id || '_' || p_slot_number;
  log('.. scheduling ' || l_job_name, l_scope);

  sys.dbms_scheduler.create_job (
      job_name        => l_job_name
    , job_type        => 'STORED_PROCEDURE'
    , job_action      => 'wmg_util.close_time_slot_time_entry'
    , number_of_arguments => 2
    , start_date      => p_job_run
    , enabled         => false
    , auto_drop       => true
    , comments        => 'Job that closes scoring 4 hoours after the time_slot begins'
  );
  
  sys.dbms_scheduler.set_job_argument_value (
     job_name          => l_job_name
   , argument_position => 1
   , argument_value    => p_tournament_session_id
  );

  sys.dbms_scheduler.set_job_argument_value (
      job_name          => l_job_name
    , argument_position => 2
    , argument_value    => p_time_slot
  );

  -- sys.dbms_scheduler.run_job(job_name => l_job_name, use_current_session => false);
  sys.dbms_scheduler.enable(name => l_job_name);


  log('END', l_scope);

  exception
    when OTHERS then
      log('Unexpected error', l_scope);
      raise;
end create_close_scoring_job;





/**
 * Create a Job `WMGT_CLOSE_SCORING` that will be called on-demand
 * at the time rooms are defined and open
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created August 6, 2023
 * @param x_result_status
 * @return
 */
procedure submit_close_scoring_jobs(
    p_tournament_session_id in wmg_tournament_sessions.id%type
)
is
  l_scope  scope_t := gc_scope_prefix || 'submit_close_scoring_jobs';
begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  log('BEGIN', l_scope);

  for slots in (
    with slots_n as (
        select level n
         from dual
         connect by level <= 6
        )
    , slots as (
        select day_offset, slot || ':00' d, slot t
        from (
            select lpad( (n-1)*4,2,0) slot, 0 day_offset
            from slots_n
            union all
            select '22' slot, -1 day_offset from dual
            union all
            select '02' slot, 0 day_offset from dual
            union all
            select '18' slot, 0 day_offset from dual
        )
    )
    , ts as (
        select s.session_date
        from wmg_tournament_sessions s
       where id = p_tournament_session_id
    )
    select t
         , slots.t || ':00' time_slot
         , to_utc_timestamp_tz(to_char(ts.session_date + slots.day_offset, 'yyyy-mm-dd') || 'T' || slots.t || ':00') UTC
         , to_utc_timestamp_tz(to_char(ts.session_date + slots.day_offset, 'yyyy-mm-dd') || 'T' || slots.t || ':00') + INTERVAL '4' HOUR job_run
    from ts
       , slots
    order by slots.day_offset, t
  )
  loop
    create_close_scoring_job(
        p_tournament_session_id => p_tournament_session_id
      , p_slot_number => slots.t
      , p_time_slot   => slots.time_slot
      , p_job_run     => slots.job_run
    );
  end loop;
  
  log('END', l_scope);

  exception
    when OTHERS then
      raise;
end submit_close_scoring_jobs;





procedure unavailable_application (p_message in varchar2 default null)
is
  c_default_message varchar2(200) := 'This application is curently being updated and will return shortly';
begin
  htp.p('<html>'
    || '<head>'
    || '<link rel="stylesheet" href="/i/22.2.0/app_ui/css/Core.min.css?v=22.2.4" type="text/css">'
    || '<link rel="stylesheet" href="/i/22.2.0/app_ui/css/Theme-Standard.min.css?v=22.2.4" type="text/css">'
    || '<link rel="stylesheet" href="/i/22.2.0/themes/theme_42/22.2/css/Redwood.min.css?v=22.2.4" type="text/css">'
    -- || '<link rel="stylesheet" href="/i/themes/theme_42/1.6/css/css/Vita.min.css" type="text/css">'
    -- || '<link rel="stylesheet" href="r/mastermind/557/files/theme/42/v70/17084618446454482.css" type="text/css">'
    || '<style>
    .t-Alert--colorBG.t-Alert--warning {
      background-color: #fef7e0;
      color: #000000;
    }
    .t-Alert--warning .t-Alert-icon .t-Icon {
      color: #FBCE4A;
    }
    .t-Alert--warning.t-Alert--horizontal .t-Alert-icon {
      background-color: rgba(251, 206, 74, 0.15);
    }
    </style>'
    || '</head>'
  );

  htp.p(
    '<div class="t-Body">'
    );

  htp.p(
     '<div class="t-Alert t-Alert--colorBG t-Alert--horizontal t-Alert--defaultIcons t-Alert--warning"'
  || ' style="width: 720px; margin: 40px auto;"' || ' id="unavailableRegion">'
  || '  <div class="t-Alert-wrap">'
  || '    <div class="t-Alert-icon">'
  || '      <span class="t-Icon "></span>'
  || '    </div>'
  || '    <div class="t-Alert-content">'
  || '      <div class="t-Alert-header">'
  || '        <h2 class="t-Alert-title" id="unavailableRegion_heading">Unavailable</h2>'
  || '      </div>'
  || '      <div class="t-Alert-body">' || nvl(p_message, c_default_message) || '</div>'
  || '    </div>'
  || '    <div class="t-Alert-buttons"></div>'
  || '  </div>'
  || '</div>'
  );

  htp.p(
    '</div>'
  ||  '</html>'
  );
end unavailable_application;


----------------------------------------
/**
 * {description here}
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created April 21, 2024
 * @param x_result_status
 * @return
 */
procedure save_stream_scores(
    p_stream_id wmg_streams.id%type
  , p_scores_json in out nocopy varchar2
)
is
  l_scope  logger_logs.scope%type := gc_scope_prefix || 'save_stream_scores';
  l_params logger.tab_param;

  l_stream_rec       wmg_streams%rowtype;
  l_stream_round_rec wmg_stream_round%rowtype;

begin
  logger.append_param(l_params, 'p_stream_id', p_stream_id);
  logger.append_param(l_params, 'p_scores_json', p_scores_json);
  logger.log('BEGIN', l_scope, null, l_params);

  select *
    into l_stream_rec
    from wmg_streams
   where id = p_stream_id;

  select *
    into l_stream_round_rec
    from wmg_stream_round
   where stream_id = p_stream_id;


  /* Merge scores for player 1 "e" */
  merge into wmg_stream_scores sc
  using (
    select s.id stream_id
         , sr.current_course_id course_id
         , sr.current_round
         , s.player1_id player_id
         , nullif(jt.es1, 0) es1
         , nullif(jt.es2, 0) es2
         , nullif(jt.es3, 0) es3
         , nullif(jt.es4, 0) es4
         , nullif(jt.es5, 0) es5
         , nullif(jt.es6, 0) es6
         , nullif(jt.es7, 0) es7
         , nullif(jt.es8, 0) es8
         , nullif(jt.es9, 0) es9
         , nullif(jt.es10, 0) es10
         , nullif(jt.es11, 0) es11
         , nullif(jt.es12, 0) es12
         , nullif(jt.es13, 0) es13
         , nullif(jt.es14, 0) es14
         , nullif(jt.es15, 0) es15
         , nullif(jt.es16, 0) es16
         , nullif(jt.es17, 0) es17
         , nullif(jt.es18, 0) es18
         , total_easy
    from wmg_streams s
       , wmg_stream_round sr
       , json_table(
          p_scores_json, -- This is the JSON string containing the scores
          '$'
          columns (
            es1 NUMBER PATH '$.es1',
            es2 NUMBER PATH '$.es2',
            es3 NUMBER PATH '$.es3',
            es4 NUMBER PATH '$.es4',
            es5 NUMBER PATH '$.es5',
            es6 NUMBER PATH '$.es6',
            es7 NUMBER PATH '$.es7',
            es8 NUMBER PATH '$.es8',
            es9 NUMBER PATH '$.es9',
            es10 NUMBER PATH '$.es10',
            es11 NUMBER PATH '$.es11',
            es12 NUMBER PATH '$.es12',
            es13 NUMBER PATH '$.es13',
            es14 NUMBER PATH '$.es14',
            es15 NUMBER PATH '$.es15',
            es16 NUMBER PATH '$.es16',
            es17 NUMBER PATH '$.es17',
            es18 NUMBER PATH '$.es18',
            total_easy NUMBER PATH '$.total_easy'
          )
        ) jt
      where s.id = sr.stream_id
        and s.id = p_stream_id
  ) src
  on (sc.stream_id = src.stream_id and sc.course_id = src.course_id and sc.course_no = src.current_round and sc.player_id = src.player_id)
  when matched then
      update set
          sc.s1 = src.es1,
          sc.s2 = src.es2,
          sc.s3 = src.es3,
          sc.s4 = src.es4,
          sc.s5 = src.es5,
          sc.s6 = src.es6,
          sc.s7 = src.es7,
          sc.s8 = src.es8,
          sc.s9 = src.es9,
          sc.s10 = src.es10,
          sc.s11 = src.es11,
          sc.s12 = src.es12,
          sc.s13 = src.es13,
          sc.s14 = src.es14,
          sc.s15 = src.es15,
          sc.s16 = src.es16,
          sc.s17 = src.es17,
          sc.s18 = src.es18,
          sc.final_score = src.total_easy
  when not matched then
      insert (
          stream_id, course_no, course_id, player_id
        , s1, s2, s3, s4, s5, s6, s7, s8, s9, s10
        , s11, s12, s13, s14, s15, s16, s17, s18
        , final_score
      )
      values (
          src.stream_id, src.current_round, src.course_id, src.player_id
        , src.es1, src.es2, src.es3, src.es4, src.es5, src.es6, src.es7, src.es8, src.es9
        , src.es10, src.es11, src.es12, src.es13, src.es14, src.es15, src.es16, src.es17, src.es18
        , src.total_easy
      );

  logger.log('p1 Rows: ' || SQL%ROWCOUNT, l_scope);
  logger.log('l_stream_round_rec.current_round: ' || l_stream_round_rec.current_round, l_scope);


  -- Update the round score for player 1
  if l_stream_round_rec.current_round = 1 then
  logger.log('l_stream_rec.player1_id:' || l_stream_rec.player1_id);
    update wmg_stream_round sr
       set sr.player1_round1_score = (
          select final_score 
            from wmg_stream_scores 
           where stream_id = p_stream_id
             and course_no = l_stream_round_rec.current_round
             and player_id = l_stream_rec.player1_id
          )
     where stream_id = p_stream_id;
  else
    update wmg_stream_round sr
       set sr.player1_round2_score = (
          select final_score 
            from wmg_stream_scores 
           where stream_id = p_stream_id
             and course_no = l_stream_round_rec.current_round
             and player_id = l_stream_rec.player1_id
          )
     where stream_id = p_stream_id;
  end if;

----------------------------------------
  /* Merge scores for player 2 "h" */
  merge into wmg_stream_scores sc
  using (
    select s.id stream_id
         , sr.current_course_id course_id
         , sr.current_round
         , s.player2_id player_id
         , nullif(jt.hs1, 0) hs1
         , nullif(jt.hs2, 0) hs2
         , nullif(jt.hs3, 0) hs3
         , nullif(jt.hs4, 0) hs4
         , nullif(jt.hs5, 0) hs5
         , nullif(jt.hs6, 0) hs6
         , nullif(jt.hs7, 0) hs7
         , nullif(jt.hs8, 0) hs8
         , nullif(jt.hs9, 0) hs9
         , nullif(jt.hs10, 0) hs10
         , nullif(jt.hs11, 0) hs11
         , nullif(jt.hs12, 0) hs12
         , nullif(jt.hs13, 0) hs13
         , nullif(jt.hs14, 0) hs14
         , nullif(jt.hs15, 0) hs15
         , nullif(jt.hs16, 0) hs16
         , nullif(jt.hs17, 0) hs17
         , nullif(jt.hs18, 0) hs18
         , total_hard
    from wmg_streams s
       , wmg_stream_round sr
       , json_table(
          p_scores_json, -- This is the JSON string containing the scores
          '$'
          columns (
            hs1 NUMBER PATH '$.hs1',
            hs2 NUMBER PATH '$.hs2',
            hs3 NUMBER PATH '$.hs3',
            hs4 NUMBER PATH '$.hs4',
            hs5 NUMBER PATH '$.hs5',
            hs6 NUMBER PATH '$.hs6',
            hs7 NUMBER PATH '$.hs7',
            hs8 NUMBER PATH '$.hs8',
            hs9 NUMBER PATH '$.hs9',
            hs10 NUMBER PATH '$.hs10',
            hs11 NUMBER PATH '$.hs11',
            hs12 NUMBER PATH '$.hs12',
            hs13 NUMBER PATH '$.hs13',
            hs14 NUMBER PATH '$.hs14',
            hs15 NUMBER PATH '$.hs15',
            hs16 NUMBER PATH '$.hs16',
            hs17 NUMBER PATH '$.hs17',
            hs18 NUMBER PATH '$.hs18',
            total_hard NUMBER PATH '$.total_hard'
          )
        ) jt
      where s.id = sr.stream_id
        and s.id = p_stream_id
  ) src
  on (sc.stream_id = src.stream_id and sc.course_id = src.course_id and sc.course_no = src.current_round and sc.player_id = src.player_id)
  when matched then
      update set
          sc.s1 = src.hs1,
          sc.s2 = src.hs2,
          sc.s3 = src.hs3,
          sc.s4 = src.hs4,
          sc.s5 = src.hs5,
          sc.s6 = src.hs6,
          sc.s7 = src.hs7,
          sc.s8 = src.hs8,
          sc.s9 = src.hs9,
          sc.s10 = src.hs10,
          sc.s11 = src.hs11,
          sc.s12 = src.hs12,
          sc.s13 = src.hs13,
          sc.s14 = src.hs14,
          sc.s15 = src.hs15,
          sc.s16 = src.hs16,
          sc.s17 = src.hs17,
          sc.s18 = src.hs18,
          sc.final_score = src.total_hard
  when not matched then
      insert (
          stream_id, course_no, course_id, player_id
        , s1, s2, s3, s4, s5, s6, s7, s8, s9
        , s10, s11, s12, s13, s14, s15, s16, s17, s18
        , final_score
      )
      values (
          src.stream_id, src.current_round, src.course_id, src.player_id
        , src.hs1, src.hs2, src.hs3, src.hs4, src.hs5, src.hs6, src.hs7, src.hs8, src.hs9
        , src.hs10, src.hs11, src.hs12, src.hs13, src.hs14, src.hs15, src.hs16, src.hs17, src.hs18
        , src.total_hard
      );

  logger.log('p2 Rows: ' || SQL%ROWCOUNT, l_scope);

  -- Update the round score for player 2
  if l_stream_round_rec.current_round = 1 then
    update wmg_stream_round sr
       set sr.player2_round1_score = (
          select final_score 
            from wmg_stream_scores 
           where stream_id = p_stream_id
             and course_no = l_stream_round_rec.current_round
             and player_id = l_stream_rec.player2_id
          )
     where stream_id = p_stream_id;
  else
    update wmg_stream_round sr
       set sr.player2_round2_score = (
          select final_score 
            from wmg_stream_scores 
           where stream_id = p_stream_id
             and course_no = l_stream_round_rec.current_round
             and player_id = l_stream_rec.player2_id
          )
     where stream_id = p_stream_id;
  end if;

  update wmg_stream_round sr
     set player1_score = sr.player1_round1_score + nvl(sr.player1_round2_score, 0)
       , player2_score = sr.player2_round1_score + nvl(sr.player2_round2_score, 0)
   where stream_id = p_stream_id;

  -- x_result_status := mm_api.g_ret_sts_success;
  logger.log('END', l_scope, null, l_params);

  exception
    when OTHERS then
      logger.log_error('Unhandled Exception', l_scope, null, l_params);
      -- x_result_status := mm_api.g_ret_sts_unexp_error;
      raise;
end save_stream_scores;


end wmg_util;
/
