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
  log('START', l_scope);

  select nvl(rooms_defined_flag, 'N')
    into l_rooms_defined_flag
    from wmg_tournament_sessions 
   where id = p_tournament_session_id;
   
  return l_rooms_defined_flag;

  exception
    when no_data_found then
      return 'N';
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

  for time_slots in (
    with slots_n as (
        select level n
         from dual
         connect by level <= 6
        )
    , slots as (
        select slot || ':00' d, slot t
        from (
            select lpad( (n-1)*4,2,0) slot
            from slots_n
        )
    )
    select d time_slot, t
    from slots
    order by t
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
      l_room_id_tbl(l_next_player).room_no := l_room;

      log('.. Room ' || l_room || ' = ' || players_on_room(l_room) || ' player(s)', l_scope);

      l_room := l_room + 1;  -- next room
      if l_room > l_rooms then
        l_room := 1;
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


  end loop; 

  log('.. Add room', l_scope);
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
  l_scope  scope_t := gc_scope_prefix || 'assign_rooms';
  -- l_params logger.tab_param;

begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  log('BEGIN', l_scope);

  log('.. removing room assignments', l_scope);
  update wmg_tournament_players
     set room_no = null
   where tournament_session_id = p_tournament_session_id;


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
 * Given a tournament session, send push notifications when the rooms have been assigned
 * to all the players that registered for this session AND opted in for push notifications.
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created September 24, 2023
 * @param p_tournament_session_id
 * @return
 */
procedure notify_room_assignments(
    p_tournament_session_id  in wmg_tournament_sessions.id%type
)
is
  l_scope  scope_t := gc_scope_prefix || 'notify_room_assignments';
  -- l_params logger.tab_param;

  c_crlf varchar2(2) := chr(13)||chr(10);

  l_room  varchar2(100);
  l_when  varchar2(100);
  l_who   varchar2(4000);

begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  log('BEGIN', l_scope);

  log('.. Loops through room assignments', l_scope);

  for push_player in (
    select distinct p.user_name, tp.player_id
      from apex_appl_push_subscriptions p
         , wmg_tournament_player_v tp
     where p.user_name = tp.account_login
       and tp.tournament_session_id = p_tournament_session_id
       and tp.active_ind = 'Y'
       and tp.rooms_open_flag = 'Y'
       -- and p.user_name like 'rimblas%' -- for testing purposes
  )
  loop
      log('.. Get room assignment for ' || push_player.user_name, l_scope);

      with my_room as (
        select p.tournament_session_id, p.time_slot, p.room_no
             , nvl(p.prefered_tz, sessiontimezone) tz
        from wmg_tournament_player_v p
        where p.active_ind = 'Y'
          and p.tournament_session_id = p_tournament_session_id
          and p.player_id = push_player.player_id
      )
      , format_room as (
        select room_no
             , player
             , to_char(local_tz, 'fmDy, fmMonth fmDD') 
              || ' ' 
              || case when tz like 'US/%' or tz like 'America%' then
                   ltrim(to_char(local_tz, 'HH:MI PM'), '0')
                 else 
                   to_char(local_tz, 'HH24:MI')
                 end
              || ' ' || tz at_local_time
        from (
          select p.tournament_player_id
               , case when s.rooms_open_flag = 'Y' then nvl2(p.room_no, 'WMGT', '') || p.room_no else '' end room_no
               , case when s.rooms_open_flag = 'Y' then '' else row_number() over (order by p.tournament_player_id) || ': ' end
              || apex_escape.html(p.player_name) player
               , to_utc_timestamp_tz(to_char(s.session_date, 'yyyy-mm-dd') || 'T' || p.time_slot) at time zone r.tz local_tz
               , r.tz
          from wmg_tournament_player_v p
             , wmg_tournament_sessions s
             , my_room r
          where s.id =  p.tournament_session_id
            and p.active_ind = 'Y'
            and p.tournament_session_id = r.tournament_session_id
            and p.time_slot = r.time_slot
            and p.room_no = r.room_no
            and s.rooms_open_flag = 'Y'
        )
        order by tournament_player_id
      )
      select room_no
           , at_local_time
           , listagg(player, ', ') players
        into l_room
           , l_when
           , l_who
        from format_room
       group by room_no, at_local_time;


      apex_pwa.send_push_notification (
        p_user_name      => push_player.user_name
      , p_title          => 'Your room is ' || l_room
      , p_body           => l_who || c_crlf
                         || 'When: ' || l_when || c_crlf
                         || 'Room: ' || l_room || c_crlf

      );
  end loop;

  log('.. push_queue!', l_scope);
  apex_pwa.push_queue;

  log('END', l_scope);

  exception
    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end notify_room_assignments;




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
      from wmg_tournament_session_points_v p
     where p.tournament_session_id = p_tournament_session_id
  ) p
  on (
        p.tournament_session_id = tp.tournament_session_id
    and p.player_id = tp.player_id
  )
  when matched then
    update
       set tp.points = nvl(tp.points_override, p.points);  -- if there's a points override, keep it.
  
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
       where ts.week = u.week
         and ts.id = tp.tournament_session_id
         and tp.player_id = u.player_id
         and tp.issue_code is null  -- only players with no issues are eligible
         and ts.id = p_tournament_session_id
         and u.score = 1
      having count(*) = 1
       group by u.course_id || ':' || u.h, u.score
     )
     group by player_id
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
       , 'DIAMOND' badge
       , 2 badge_count
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
   *    (1x) Top 20  -or- (3x) Top 20 with 9 pts.
   */

  log('.. Advance to SEMI-PRO', l_scope);
  update wmg_players
     set rank_code = 'SEMI'
   where id in (
    select p.player_id
      from wmg_tournament_session_points_v p
     where p.tournament_session_id = p_tournament_session_id
       and p.pos <= 20
       and p.rank_code not in ('PRO', 'SEMI')
   );
  
  log(SQL%ROWCOUNT || ' rows updated.', l_scope);



  /*
   *    PRO status can be achieved by the following:
   *    (1x) Top 5 -or- (3x) Top 10 
   */

  log('.. Advance to PRO', l_scope);
  update wmg_players
     set rank_code = 'PRO'
   where id in (
    select p.player_id
      from wmg_tournament_session_points_v p
     where p.tournament_session_id = p_tournament_session_id
       and p.pos <= 5
       and p.rank_code != 'PRO'
   );
  
  log(SQL%ROWCOUNT || ' rows updated.', l_scope);



  log('END', l_scope);

end promote_players;




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

  if g_must_be_current then -- make sure it's the current tournament. Only false for historical loads
    log('.. promote players', l_scope);
    promote_players(
        p_tournament_id         => p_tournament_id
      , p_tournament_session_id => p_tournament_session_id
    );
  end if;


  log('.. close tournament session', l_scope);
  update wmg_tournament_sessions ts
     set ts.completed_ind = 'Y'
       , ts.completed_on = current_timestamp
   where ts.id = p_tournament_session_id
     and ts.tournament_id = p_tournament_id;

  log('END', l_scope);

  exception
    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end close_tournament_session;





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
    );

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

  begin
      select *
        into l_issue_rec
        from wmg_issues
       where code = c_issue_noshow;
  exception 
    -- protect against errors in case the issue is gone
    when no_data_found then
      l_issue_rec.code := c_issue_noshow;
      l_issue_rec.description := 'No show or No Score';
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
        select slot || ':00' d, slot t
        from (
            select lpad( (n-1)*4,2,0) slot
            from slots_n
        )
    )
    , ts as (
        select s.session_date
        from wmg_tournament_sessions s
       where id = p_tournament_session_id
    )
    select t
         , slots.t || ':00' time_slot
         , to_utc_timestamp_tz(to_char(ts.session_date, 'yyyy-mm-dd') || 'T' || slots.t || ':00') UTC
         , to_utc_timestamp_tz(to_char(ts.session_date, 'yyyy-mm-dd') || 'T' || slots.t || ':00') + INTERVAL '4' HOUR job_run
    from ts
       , slots
    order by t
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
  l_attepts number;
begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  log('BEGIN', l_scope);

  for u in (
  with course_play_count as (
        select c.course_id, count(*) play_count, max(s.week) week, max(s.session_date) session_date
        from wmg_tournament_courses c
           , wmg_tournament_sessions s
        where s.id = c.tournament_session_id
          and s.session_date <= (select ts.session_date from wmg_tournament_sessions ts where ts.id = p_tournament_session_id)
        group by c.course_id
  )
  , courses_played as (
      select c.course_id, c.name course_name, cc.play_count, cc.week, cc.session_date
      from wmg_courses_v  c
         , course_play_count cc
      where c.course_id = cc.course_id
        and cc.play_count >= 5
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
      into l_attepts
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
       , l_attepts
       , ts.id                    score_tournament_session_id
       , p_tournament_session_id  award_tournament_session_id
     from wmg_tournament_sessions ts
     where ts.week = u.week;

    log('Added ' || SQL%ROWCOUNT, l_scope);
  end loop;

  log('END', l_scope);

  exception
    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end add_unicorns;




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


end wmg_util;
/
