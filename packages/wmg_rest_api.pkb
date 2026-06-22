create or replace package body wmg_rest_api
is

--------------------------------------------------------------------------------
-- CONSTANTS
--------------------------------------------------------------------------------

gc_scope_prefix constant varchar2(31) := lower($$PLSQL_UNIT) || '.';
subtype scope_t is varchar2(128);

--------------------------------------------------------------------------------
-- UTILITY FUNCTIONS
--------------------------------------------------------------------------------

function format_session_date_utc(
    p_date in date
  , p_time_slot in varchar2 default '00:00'
) return varchar2
is
  l_scope scope_t := gc_scope_prefix || 'format_session_date_utc';
begin
    $IF $$VERBOSE_OUTPUT $THEN
    logger.log('START', l_scope);
    logger.log(p_text => '.. p_date: ' || p_date, p_scope => l_scope);
    $END
    return to_char(p_date, 'YYYY-MM-DD') || '"T"' || p_time_slot || ':SS"Z"';
end format_session_date_utc;



function convert_session_date_utc(
    p_date in date
  , p_time_slot in varchar2 default '00:00'
) return  timestamp with time zone
is
  l_scope scope_t := gc_scope_prefix || 'convert_session_date_utc';
begin
    $IF $$VERBOSE_OUTPUT $THEN
    logger.log('START', l_scope);
    logger.log(p_text => '.. p_date: ' || p_date, p_scope => l_scope);
    $END

    return from_tz(
         cast(p_date
              + to_dsinterval('0 ' || p_time_slot || ':0') as timestamp),  -- uses to_dsinterval ('DD HH24:MI:SS') directly with the string '0 HH24:MI:SS'.
         'UTC'
       ); 
end convert_session_date_utc;






function format_session_date_local(
    p_date      in date
  , p_time_slot in varchar2
  , p_timezone  in varchar2
) return varchar2
is
  l_scope scope_t := gc_scope_prefix || 'format_session_date_local';

  l_local_date timestamp with time zone;
  l_local varchar2(200);
begin
    $IF $$VERBOSE_OUTPUT $THEN
    logger.log('START', l_scope);
    logger.log(p_text => '.. p_date: ' || p_date, p_scope => l_scope);
    logger.log(p_text => '.. p_time_slot: ' || p_time_slot, p_scope => l_scope);
    logger.log(p_text => '.. p_timezone: ' || p_timezone, p_scope => l_scope);
    $END

    if p_date is null then
        return null;
    end if;
    if p_timezone is null then
        return format_session_date_utc(p_date);
    end if;

  -- get the time_slot in UTC
  select from_tz(
         cast((p_date + ts.day_offset)
              + to_dsinterval('0 ' || ts.time_slot || ':0') as timestamp),
         'UTC'
       ) as utc
    into l_local_date
    from wmg_time_slots_all_v ts
   where ts.time_slot = p_time_slot;

  -- get the local user time without timezone
  $IF $$VERBOSE_OUTPUT $THEN
  logger.log(l_local_date);
  $END

  -- add the timezone
  l_local_date := l_local_date  at time zone p_timezone;
  -- get the local user time
  $IF $$VERBOSE_OUTPUT $THEN
  logger.log(l_local_date);
  $END

--   return to_char(l_local_date, 'YYYY-MM-DD"T"HH24:MI:SS"Z"');
  return to_char(l_local_date, 'fmDy, fmMonth fmDD') 
      || ', ' 
      || case when p_timezone like 'US/%' or p_timezone like 'America%' then
           ltrim(to_char(l_local_date, 'HH:MI PM'), '0')
         else 
           to_char(l_local_date, 'HH24:MI')
         end
      || ' ' || p_timezone;
exception
  when others then
     logger.log_error(p_text => 'Unexpected error', p_scope => l_scope);
    return format_session_date_utc(p_date);
end format_session_date_local;





-- Convert the date for a time_slot  to epoch (UNIX timestamp)
-- this is used by Discord to present dates in the users localtime
function format_session_date_epoch(
    p_date      in date
  , p_time_slot in varchar2
) return number
is
  l_scope scope_t := gc_scope_prefix || 'format_session_date_epoch';

  l_utc_date timestamp with time zone;
  l_epoch number;
begin
   $IF $$VERBOSE_OUTPUT $THEN
   logger.log('START', l_scope);
   logger.log(p_text => '.. p_date: ' || p_date, p_scope => l_scope);
   logger.log(p_text => '.. p_time_slot: ' || p_time_slot, p_scope => l_scope);  
   $END


   select convert_session_date_utc(
              p_date => p_date + ts.day_offset
            , p_time_slot => ts.time_slot
          )
    into l_utc_date
    from wmg_time_slots_all_v ts
   where ts.time_slot = p_time_slot;

  -- logger.log(p_text => '.. l_utc_date: ' || l_utc_date, p_scope => l_scope);
  l_epoch := round(
                  ( extract(day    from (l_utc_date at time zone 'UTC' 
                                         - timestamp '1970-01-01 00:00:00 UTC')) * 86400   -- 86400 is the number of seconds in a day
                  + extract(hour   from (l_utc_date at time zone 'UTC' 
                                         - timestamp '1970-01-01 00:00:00 UTC')) * 3600
                  + extract(minute from (l_utc_date at time zone 'UTC' 
                                         - timestamp '1970-01-01 00:00:00 UTC')) * 60
                  + extract(second from (l_utc_date at time zone 'UTC' 
                                         - timestamp '1970-01-01 00:00:00 UTC'))
                  )
              );
  $IF $$VERBOSE_OUTPUT $THEN
  logger.log(p_text => '.. l_epoch: ' || l_epoch, p_scope => l_scope);
  $END

  return l_epoch;

exception
  when others then
     logger.log_error(p_text => 'Unexpected error', p_scope => l_scope);
    return 0;
end format_session_date_epoch;





function format_uptime(p_seconds number, p_short varchar2 default 'N')
return varchar2
is
  l_days    number;
  l_hours   number;
  l_minutes number;
  l_seconds number;
begin
  l_days    := floor(p_seconds / 86400);
  l_hours   := floor(mod(p_seconds, 86400) / 3600);
  l_minutes := floor(mod(p_seconds, 3600) / 60);
  l_seconds := floor(mod(p_seconds, 60));
  
  if upper(p_short) = 'Y' then
    -- Short format: 12d 10:47:49
    return case when l_days > 0 then l_days || 'd ' else '' end ||
           lpad(l_hours, 2, '0') || ':' ||
           lpad(l_minutes, 2, '0') || ':' ||
           lpad(l_seconds, 2, '0');
  else
    -- Long format: 12 days, 10 hours, 47 minutes, 49 seconds
    return case when l_days > 0 then l_days || ' days, ' else '' end ||
           case when l_hours > 0 then l_hours || ' hours, ' else '' end ||
           l_minutes || ' minutes, ' ||
           l_seconds || ' seconds';
  end if;
end format_uptime;



/*
* Given a tournament_session_id and a room_no return the players in that room
*/
function build_room_players_json(
    p_tournament_session_id in wmg_tournament_sessions.id%type
  , p_room_no               in wmg_tournament_players.room_no%type
) return clob
is
  l_room_players_json clob;
begin
  select json_arrayagg(
           json_object(
               'player_name' value p.player_name
             , 'isNew' value case when  p.rank_code = 'NEW' then 'true' else 'false' end format json
           )
           returning clob
         )
    into l_room_players_json
    from wmg_tournament_player_v p
    where p.tournament_session_id = p_tournament_session_id
      and p.room_no = p_room_no
      and p.active_ind = 'Y';
  
  return l_room_players_json;
end build_room_players_json;


/*
* Given a session_id return the courses that will be played
*/
function build_courses_json(p_session_id in number) return clob
is
  l_courses_json clob;
begin
  select json_arrayagg(
           json_object(
               'course_no' value case when tc.course_no = 1 then 1 else 2 end
             , 'course_name' value c.name
             , 'course_code' value c.code
             , 'difficulty' value case when tc.course_no = 1 then 'Easy' else 'Hard' end
           )
           returning clob
         )
    into l_courses_json
    from wmg_tournament_courses tc
    join wmg_courses c on tc.course_id = c.id
   where tc.tournament_session_id = p_session_id;
  
  return l_courses_json;
end build_courses_json;


function get_player_moderation_message(
    p_player_id  in wmg_players.id%type
  , p_session_id in wmg_tournament_sessions.id%type
) return wmg_player_moderation.player_message%type
is
  l_moderation_count pls_integer;
  l_message wmg_player_moderation.player_message%type;
begin
  select count(*)
       , coalesce(max(m.player_message), 'You have been banned !')
    into l_moderation_count
       , l_message
    from wmg_player_moderation m
   where m.player_id = p_player_id
     and (
        m.banned_flag = 'Y'
      or (  m.timeout_flag = 'Y'
        and m.timeout_tournament_id in (
              select tournament_id
                from wmg_tournament_sessions
               where id = p_session_id
            )
       )
      or (  m.timeout_flag = 'Y'
        and m.timeout_end_date < current_timestamp
       )
     )
     and m.active_ind = 'Y';

  if l_moderation_count > 0 then
    return l_message;
  end if;

  return null;
end get_player_moderation_message;



--------------------------------------------------------------------------------
-- RESPONSE PROCEDURES
--------------------------------------------------------------------------------

procedure error_response(
    p_error_code in varchar2
  , p_message in varchar2
)
is
begin
  apex_json.open_object;
  apex_json.write('success', false);
  apex_json.write('error_code', p_error_code);
  apex_json.write('message', p_message);
  apex_json.close_object;
end error_response;




procedure success_response(
    p_message in varchar2
  , p_data in clob default null
)
is
begin
  apex_json.open_object;
  apex_json.write('success', true);
  apex_json.write('message', p_message);
  if p_data is not null then
    apex_json.write_raw('data', p_data);
  end if;
  apex_json.close_object;
end success_response;




procedure current_tournament(
  p_tournament_type_code in wmg_tournament_control.tournament_type_code%type default 'WMGT'
)
is
  l_scope scope_t := gc_scope_prefix || 'current_tournament';

  l_clob clob;
  l_tournament_session_id number;
begin
  logger.log(p_text => 'START', p_scope => l_scope);
  logger.log(p_text => '.. p_tournament_type_code: ' || p_tournament_type_code, p_scope => l_scope);
  
  -- Get the current tournament session ID from the control table
  l_tournament_session_id := wmg_util.get_tournament_control(p_tournament_type_code);
  
  -- Handle NULL tournament_session_id case (tournament break)
  if l_tournament_session_id is null then
    goto no_tournament_open;
    error_response(
        p_error_code => c_error_no_active_tournament_session
      , p_message => 'No available ' || p_tournament_type_code || ' tournaments at the time.'
    );
    return;
  end if;
  
  logger.log(p_text => '.. l_tournament_session_id: ' || l_tournament_session_id, p_scope => l_scope);
  
  select json_object(
    'tournament' value json_object(
      'id' value t.tournament_id,
      'name' value t.name,
      'code' value t.code
    )
    ,'sessions' value json_object(
          'id' value t.tournament_session_id,
          'week' value t.week,
          'session_date' value to_char(t.session_date, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
          'open_registration_on' value to_char(t.open_registration_on, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
          'close_registration_on' value to_char(t.close_registration_on, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
          'tournament_state' value 
              case 
                 when t.rooms_open_flag = 'Y' and t.completed_ind = 'N' then 'ongoing'
                 when t.completed_ind = 'Y' or t.registration_closed_flag is not null then 'closed'
                 when t.registration_closed_flag is null then 'open'
              end,
          'registration_open' value case
            when t.registration_closed_flag is null 
            then 'true' else 'false'
            end format json
            ,'available_time_slots' value (
            select json_arrayagg(
              json_object(
                'time_slot' value ts.time_slot,
                'day_offset' value ts.day_offset,
                'display' value ts.prepared_time_slot,
                'session_date_epoch' value format_session_date_epoch(t.session_date, ts.time_slot),
                'time_slot_status' value 
                 case
                   when systimestamp between 
                          to_utc_timestamp_tz(to_char(t.session_date + ts.day_offset,             'yyyy-mm-dd') || 'T' || ts.time_slot) 
                      and to_utc_timestamp_tz(to_char(t.session_date + nvl(ts.next_day_offset,0), 'yyyy-mm-dd') || 'T' || nvl(ts.next_time_slot, '22:00')) - NUMTODSINTERVAL(1, 'SECOND')   then 'current' 
                   when to_utc_timestamp_tz(to_char(t.session_date + ts.day_offset,      'yyyy-mm-dd') || 'T' || ts.time_slot)  < systimestamp - NUMTODSINTERVAL(2, 'MINUTE') then 'done' 
                   else ''
                 end,
                'player_count' value (
                    select count(*) from wmg_tournament_players p 
                     where p.tournament_session_id = wts.id and p.time_slot = ts.time_slot
                       and p.active_ind = 'Y')
              ) order by ts.seq
            )
            from wmg_time_slots_all_v ts
            left join wmg_tournament_sessions wts on 1=1 and wts.id = t.tournament_session_id
          )
          ,'courses' value (
            select json_arrayagg(
              json_object(
                'course_no' value case when tc.course_no = 1 then 1 else 2 end,
                'course_name' value c.name,
                'course_code' value c.code,
                'difficulty' value case when c.course_mode = 'E' then 'Easy' else 'Hard' end
              )
            )
            from wmg_tournament_courses tc
            join wmg_courses c on tc.course_id = c.id
            where tc.tournament_session_id = t.tournament_session_id
          )
          ,'results' value (
            select json_arrayagg(
              json_object(
                'pos' value r.pos,
                'player_name' value r.player_name,
                'discord_id' value r.discord_id,
                'total_score' value r.total_score
              ) order by r.pos
            )
            from wmg_tournament_session_points_v r
            where r.tournament_session_id = t.tournament_session_id
              and r.pos <= 5
          )
        -- returning clob
      )
    )
    -- returning clob
  into l_clob
  from (
    select t.id tournament_id, t.name, t.code
      , s.id tournament_session_id
      , s.week
      , s.session_date
      , s.rooms_open_flag
      , s.open_registration_on
      , s.close_registration_on
      , s.completed_ind
      , s.registration_closed_flag
   from wmg_tournament_sessions s
   join wmg_tournaments t on s.tournament_id = t.id
   where s.id = l_tournament_session_id
  ) t;

  <<no_tournament_open>>
  if l_clob is null then
    l_clob := '{"tournament": null}';
    /*
    json_object(
      'tournament' value null,
      'sessions' value json_array()
    );
    */
    logger.log(p_text => 'No tournament session found for ID: ' || l_tournament_session_id, p_scope => l_scope);
  end if;

 sys.owa_util.mime_header('application/json', true);
  apex_util.prn(
    p_clob   => l_clob,
    p_escape => false
  );


  logger.log(p_text => 'END', p_scope => l_scope);
exception
  when others then
    -- Handle unexpected application errors from tournament control procedures
    error_response(
        p_error_code => c_error_invalid_tournament_session
      , p_message => 'Unknown error:' || sqlerrm
    );
    logger.log_error(p_text => sqlerrm, p_scope => l_scope);
end current_tournament;



/*
 * Return JSON information about a player registration
 * ```
 {
    "player": {
        "discord_id": 11111,
        "id": 3827,
        "name": "String",
        "timezone": "Europe/Warsaw"
    },
    "registrations": [
        {
            "courses": [
                {
                    "course_code": "CLE",
                    "course_name": "Crystal Lair",
                    "course_no": 1,
                    "difficulty": "Easy"
                },
                {
                    "course_code": "CLH",
                    "course_name": "Crystal Lair - Hard",
                    "course_no": 2,
                    "difficulty": "Hard"
                }
            ],
            "session_id": 1234,
            "week": "S17W12",
            "session_date": "2025-08-24T00:00:00Z",
            "time_slot": "22:00",
            "session_local_tz": "2025-08-24T00:00:00Z",
            "room_no": null,
        }
    ]
}
```
*
*
*/
procedure player_registrations(
    p_discord_id in varchar2
)
is
  l_scope scope_t := gc_scope_prefix || 'player_registrations';

  l_player_id wmg_players_v.id%type;
  l_player_name wmg_players_v.player_name%type;
  l_player_timezone wmg_players_v.prefered_tz%type;

  l_output clob;
  l_epoch number;
begin
  logger.log(p_text => 'START', p_scope => l_scope);
  logger.log(p_text => '.. discord_id: ' || p_discord_id, p_scope => l_scope);

  -- Get player info
  select id
       , player_name
       , prefered_tz
    into l_player_id
       , l_player_name
       , l_player_timezone
    from wmg_players_v
   where discord_id = to_number(p_discord_id default null on conversion error);

  logger.log(p_text => '.. player_timezone: ' || l_player_timezone, p_scope => l_scope);

  select json_object(
           'player' value json_object(
               'id' value l_player_id
             , 'name' value l_player_name
             , 'discord_id' value p_discord_id
             , 'timezone' value l_player_timezone
           )
         , 'registrations' value (
             select json_arrayagg(
                      json_object(
                          'session_id' value tp.tournament_session_id
                        , 'week' value ts.week
                        , 'time_slot' value tp.time_slot
                        , 'session_date' value format_session_date_utc(ts.session_date)
                        , 'session_date_formatted' value format_session_date_local(ts.session_date, tp.time_slot, 'UTC')
                        , 'session_local_tz' value format_session_date_local(ts.session_date, tp.time_slot, l_player_timezone)
                        , 'session_local_tz' value format_session_date_local(ts.session_date, tp.time_slot, l_player_timezone)
                        , 'session_date_epoch' value format_session_date_epoch(ts.session_date, tp.time_slot)
                        , 'room_no' value nvl2(tp.room_no, t.prefix_room_name, '') || tp.room_no
                        , 'room_players' value build_room_players_json(ts.id, tp.room_no) format json
                        , 'courses' value build_courses_json(ts.id) format json
                      )
                      order by ts.session_date
                      returning clob
                    )
               from wmg_tournaments t
               join wmg_tournament_sessions ts on t.id = ts.tournament_id
               join wmg_tournament_players tp on tp.tournament_session_id = ts.id
              where tp.player_id = l_player_id
                and tp.active_ind = 'Y'
                and ts.session_date + 1 >= trunc(current_timestamp)
                and ts.completed_ind = 'N'
           )
           returning clob
         )
    into l_output
    from dual;

  if l_output is null then
    apex_json.open_object;
    apex_json.open_object('player');
    apex_json.write('id', l_player_id);
    apex_json.write('name', l_player_name);
    apex_json.write('discord_id', p_discord_id);
    apex_json.write('timezone', l_player_timezone);
    apex_json.close_object;
    apex_json.open_array('registrations');
    apex_json.close_array;
    apex_json.close_object;
  else
    -- logger.log(l_output);
    sys.owa_util.mime_header('application/json', true);
    apex_util.prn(
        p_clob   => l_output
      , p_escape => false
    );
  end if;

  logger.log(p_text => 'END', p_scope => l_scope);
exception
  when no_data_found then
    error_response(
        p_error_code => c_error_player_not_found
      , p_message => 'Discord user not linked to WMGT player account'
    );
    logger.log_error(p_text => 'Player not found: ' || p_discord_id, p_scope => l_scope);
  when others then
    logger.log_error(p_text => sqlerrm, p_scope => l_scope);
    raise;
end player_registrations;





procedure handle_registration(
    p_body in clob
)
is
  l_scope scope_t := gc_scope_prefix || 'handle_registration';
  
  l_json json_object_t;
  l_discord_user t_discord_user;
  l_session_id number;
  l_time_slot varchar2(5);
  l_timezone wmg_players.prefered_tz%type;
  l_existing_registration number;
  l_registration_open varchar2(1);
  l_week varchar2(10);
  l_response clob;
  l_player_rank_code wmg_players.rank_code%type;
  l_valid_slot_count number;
  l_moderation_message wmg_player_moderation.player_message%type;
begin
  logger.log(p_text => 'START', p_scope => l_scope);

  -- Get request body
  l_json := json_object_t.parse(p_body);

  -- Extract parameters
  l_session_id := l_json.get_number('session_id');
  l_time_slot := l_json.get_string('time_slot');
  l_timezone  := l_json.get_string('time_zone');

  logger.log(p_text => 'session_id: ' || l_session_id || ', time_slot: ' || l_time_slot || ', timezone: ' || l_timezone, p_scope => l_scope);

  -- Validate session exists and registration is open
  select case
        when registration_closed_flag is null
        then 'Y' else 'N' end
       , week
  into l_registration_open, l_week
  from wmg_tournament_sessions
  where id = l_session_id;

  if l_registration_open = 'N' then
    error_response(
        p_error_code => 'REGISTRATION_CLOSED'
      , p_message => 'Registration for this tournament session has closed'
  );
    return;
  end if;

  -- Initialize Discord user from JSON
  l_discord_user := t_discord_user();
  l_discord_user.init_from_json(l_json.get_object('discord_user').to_clob());
  l_discord_user.sync_player();

  l_moderation_message := get_player_moderation_message(
      p_player_id  => l_discord_user.player_id
    , p_session_id => l_session_id
  );

  if l_moderation_message is not null then
    error_response(
        p_error_code => c_error_player_moderated
      , p_message    => l_moderation_message
    );
    return;
  end if;

  if l_timezone is not null then
      update wmg_players
         set prefered_tz = l_timezone
       where id = l_discord_user.player_id;
  end if;

  logger.log(p_text => 'player_id: ' || l_discord_user.player_id, p_scope => l_scope);

  -- Check if this a brand new player, new players need to finish their registration on the website
  select rank_code
  into l_player_rank_code
  from wmg_players
  where id = l_discord_user.player_id;

  if l_player_rank_code = 'NEW' then
    error_response(
        p_error_code => 'NEW_PLAYER_NEEDS_SETUP'
      , p_message => 'Apologies, as a new player please visit [MyWMGT.com](https://mywmgt.com) to register'
  );
    return;
  end if;

  -- Check if already registered for this session
  select count(*)
  into l_existing_registration
  from wmg_tournament_players
  where tournament_session_id = l_session_id
    and player_id = l_discord_user.player_id
    and active_ind = 'Y';

  if l_existing_registration > 0 then
    logger.log(p_text => '.. already registered. maybe changing time_slot', p_scope => l_scope);
  end if;

  -- Validate time slot
  select count(*)
  into l_valid_slot_count
  from wmg_time_slots_all_v
  where time_slot = l_time_slot;

  if l_valid_slot_count = 0 then
    error_response(
        p_error_code => 'INVALID_TIME_SLOT'
      , p_message => 'Selected time slot is not available'
    );
    return;
  end if;

  -- Register player
  wmg_util.process_registration(
    p_tournament_session_id => l_session_id
  , p_player_id   => l_discord_user.player_id
  , p_action      => 'SIGNUP'
  , p_time_slot   => l_time_slot
  , p_source      => 'API'
  );

  commit;

  success_response(
      p_message => 'Successfully registered for ' || l_week || ' at ' || l_time_slot || ' UTC'
    , p_data => json_object(
          'registration' value json_object(
              'session_id' value l_session_id
            , 'week' value l_week
            , 'time_slot' value l_time_slot
          )
        )
  );

  logger.log(p_text => 'END', p_scope => l_scope);

exception
  when no_data_found then
    error_response(
        p_error_code => 'SESSION_NOT_FOUND'
      , p_message => 'Tournament session does not exist'
    );
    logger.log_error(p_text => 'Session not found: ' || l_session_id, p_scope => l_scope);
  when others then
    rollback;
    error_response(
        p_error_code => 'REGISTRATION_FAILED'
      , p_message => 'Registration failed: ' || sqlerrm
    );
    logger.log_error(p_text => sqlerrm, p_scope => l_scope);
end handle_registration;




procedure purge_rest_requests
is
  l_scope scope_t := gc_scope_prefix || 'purge_rest_requests';

  l_count number;
begin
    logger.time_start(l_scope);
    logger.log('.. purging old requests', l_scope);

    delete from wmg_rest_request
     where created_on < systimestamp - interval '8' day;

    l_count := sql%rowcount;

    logger.log('.. deleted rows: ' || nvl(to_char(l_count),'0'), l_scope);
    logger.time_stop(l_scope);

end purge_rest_requests;




procedure get_data(
    p_source_code in     wmg_rest_sources.source_code%type
  , x_request_id  in out wmg_rest_request.id%type
)
is
  l_scope  scope_t := gc_scope_prefix || 'get_data';

  l_source_id   wmg_rest_sources.id%type;
  l_url         wmg_rest_sources.url%type;
  l_req_clob    clob;
  l_resp_clob   clob;
  l_status_code number;
  l_start_ts    timestamp := systimestamp;
  l_duration_ms number;
  l_error_message varchar2(4000);
begin
    logger.time_start(l_scope);
    logger.log('.. source:' || p_source_code, l_scope);

    begin
        -- find active source (support either case)
        select id, url
        into l_source_id, l_url
        from wmg_rest_sources
        where source_code = p_source_code
        and active_ind = 'Y';
    exception
        when no_data_found then
            logger.time_stop(l_scope);
            raise_application_error(-20001, 'Invalid or inactive source for code: ' || p_source_code);
    end;

    -- create request row and return generated id
    insert into wmg_rest_request (
      source_code
    , endpoint_url
    , http_method
    )
    values (
      p_source_code
    , l_url
    , 'GET'
    )
    returning id into x_request_id;

    logger.log('.. starting request, source=' || p_source_code || ', url=' || l_url || ', request_id=' || x_request_id, l_scope);

    begin
        -- perform rest call using apex_web_service
        l_resp_clob := apex_web_service.make_rest_request(
        p_url         => l_url
        , p_http_method => 'GET'
        );

        l_status_code := apex_web_service.g_status_code;

        l_duration_ms := round((cast(systimestamp as date) - cast(l_start_ts as date)) * 24 * 60 * 60 * 1000,2);

        -- update request with response
        update wmg_rest_request
            set response_payload = l_resp_clob
        , status_code      = l_status_code
        , duration_ms      = l_duration_ms
        where id = x_request_id;

        logger.log('.. completed request_id=' || x_request_id || ', status=' || nvl(to_char(l_status_code), 'n/a'), l_scope);

    exception
        when others then
            logger.log_error('.. error for request_id=' || x_request_id, l_scope);

            l_error_message := sqlerrm;

            update wmg_rest_request
                set response_payload = null
                , status_code      = null
                , is_error_flag    = 'Y'
                , error_message    = l_error_message
                , duration_ms      = round((cast(systimestamp as date) - cast(l_start_ts as date)) * 24 * 60 * 60 * 1000)
            where id = x_request_id;

    end;

    purge_rest_requests;

    logger.time_stop(l_scope);
    commit;

end get_data;



/**
 * Loop over all the active sources and refresh their data.
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created September 13, 2025
 * @param
 * @return
 */
procedure refresh_all_sources
is
  l_scope  logger_logs.scope%type := gc_scope_prefix || 'refresh_all_sources';
  l_params logger.tab_param;

  l_request_id wmg_rest_request.id%type;
begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  logger.log('BEGIN', l_scope, null, l_params);

  for s in (
    select source_code 
      from wmg_rest_sources
     where active_ind = 'Y'
     )
  loop
    l_request_id := null;
    get_data(
        p_source_code => s.source_code
      , x_request_id  => l_request_id
    );
  end loop;  

  logger.log('END', l_scope, null, l_params);

  exception
    when OTHERS then
      logger.log_error('Unhandled Exception', l_scope, null, l_params);
      -- x_result_status := mm_api.g_ret_sts_unexp_error;
      raise;
end refresh_all_sources;



/**
 * Create a Job `PROCESS_REFRESH_ALL_SOURCES` that will run:
 8  - Every 4 hours Monday to Friday
 9  - Every 2 hours Saturday and Sunday
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created September 15, 2025
 * @param
 * @return
 */
procedure schedule_refresh_all_sources
is
  l_scope  scope_t := gc_scope_prefix || 'schedule_refresh_all_sources';

  l_job_name  varchar2(100);
begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  logger.log('BEGIN', l_scope);

  l_job_name := 'PROCESS_REFRESH_ALL_SOURCES';

  begin
    sys.dbms_scheduler.drop_job (job_name => l_job_name || '_DAYS');
    sys.dbms_scheduler.drop_job (job_name => l_job_name || '_ENDS');
  exception
    when others then null;
  end;
      

  logger.log('.. scheduling ' || l_job_name, l_scope);

  sys.dbms_scheduler.create_job (
      job_name        => l_job_name || '_DAYS'
    , job_type        => 'STORED_PROCEDURE'
    , job_action      => 'wmg_rest_api.refresh_all_sources'
    , number_of_arguments => 0
--    , start_date      => from_tz(cast(trunc(sysdate) as timestamp), 'UTC') -- Morning UTC = ~ 7pm Central
    , repeat_interval => 'FREQ=HOURLY; INTERVAL=4; BYDAY=MON,TUE,WED,THU,FRI;'
    , enabled         => true
    , auto_drop       => true
    , comments        => 'Job that refreshes all sources metrics'
  );
  
  sys.dbms_scheduler.create_job (
      job_name        => l_job_name || '_ENDS'
    , job_type        => 'STORED_PROCEDURE'
    , job_action      => 'wmg_rest_api.refresh_all_sources'
    , number_of_arguments => 0
    , repeat_interval => 'FREQ=HOURLY; INTERVAL=2; BYDAY=SAT,SUN;'
    , enabled         => true
    , auto_drop       => true
    , comments        => 'Job that refreshes all sources metrics'
  );
  

  logger.log('END', l_scope);

  exception
    when OTHERS then
      logger.log_error('Unexpected error', l_scope);
      raise;
end schedule_refresh_all_sources;


end wmg_rest_api;
/
