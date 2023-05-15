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


    log('.. Add room', l_scope);
    forall idx in 1 .. l_room_id_tbl.count
      insert into wmg_tournament_rooms (
          tournament_session_id
        , time_slot
        , room_no
      )
      values (
          p_tournament_session_id
        , time_slots.time_slot
        , l_room_id_tbl(idx).room_no
      );


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
          select p.id, p.player_name, utl_match.jaro_winkler_similarity(upper(p_discord_account), upper(p.player_name)) similarity
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
       set points = p.points;
  
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

  log('.. Top 10 player badges');
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
         end
       , 1
    from wmg_tournament_session_points_v p
   where p.tournament_session_id = p_tournament_session_id
     and p.pos <=10;


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
     where ts.week = u.week
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
       where ts.week = u.week
         and ts.id = p_tournament_session_id
         and u.score = 1
      having count(*) = 1
       group by u.course_id || ':' || u.h, u.score
     )
     group by player_id
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
     and p.player_id = cactus.player_id;
  
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
           and current_flag = 'Y'
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
           and current_flag = 'Y'
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
   *    (1x) Top 15  -or- (3x) Top 20 with 9 pts.
   */

  log('.. Advance to SEMI-PRO', l_scope);
  update wmg_players
     set rank_code = 'SEMI'
   where id in (
    select p.player_id
      from wmg_tournament_session_points_v p
     where p.tournament_session_id = p_tournament_session_id
       and p.pos <= 15
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

  log('.. promote players', l_scope);
  promote_players(
      p_tournament_id         => p_tournament_id
    , p_tournament_session_id => p_tournament_session_id
  );


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
