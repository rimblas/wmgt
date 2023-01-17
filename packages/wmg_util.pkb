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
 * @param x_result_status
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
      exit when l_room_id_tbl(l_player).room_no is null and i < l_max;
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

    log('.. Assigning Rooms for ' || time_slots.time_slot || ' playesr ' || l_room_id_tbl.count, l_scope);
    
    l_players := l_room_id_tbl.count;
    l_rooms := rooms(p_player_count => l_players);
    l_room := 1;

    log('.. Will need ' || l_rooms || ' Rooms', l_scope);

    <<room_distribution>>
    while l_players > 0
    loop

      
      l_next_player := get_next_player();
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

 log('.. Stamp room assignments', l_scope);
  update wmg_tournament_sessions
     set rooms_defined_flag = 'Y'
       , rooms_defined_by   = coalesce(sys_context('APEX$SESSION','APP_USER'),user) 
       , rooms_defined_on   = current_timestamp
    where id = p_tournament_session_id;

  log('END', l_scope);

  exception
    when OTHERS then
      log('Unhandled Exception', l_scope);
      raise;
end assign_rooms;




end wmg_util;
/
