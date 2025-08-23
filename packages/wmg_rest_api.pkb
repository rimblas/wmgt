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
    logger.log('START', l_scope);
    logger.log(p_text => '.. p_date: ' || p_date, p_scope => l_scope);
    return to_char(p_date, 'YYYY-MM-DD') || '"T"' || p_time_slot || ':SS"Z"';
end format_session_date_utc;



function convert_session_date_utc(
    p_date in date
  , p_time_slot in varchar2 default '00:00'
) return  timestamp with time zone
is
  l_scope scope_t := gc_scope_prefix || 'convert_session_date_utc';
begin
    logger.log('START', l_scope);
    logger.log(p_text => '.. p_date: ' || p_date, p_scope => l_scope);

    return from_tz(
         cast(p_date
              + to_dsinterval('0 ' || p_time_slot || ':0') as timestamp),  -- uses to_dsinterval ('DD HH24:MI:SS') directly with the string '0 HH24:MI:SS'.
         'UTC'
       ); 
end convert_session_date_utc;



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
    logger.log('START', l_scope);
    logger.log(p_text => '.. p_date: ' || p_date, p_scope => l_scope);
    logger.log(p_text => '.. p_time_slot: ' || p_time_slot, p_scope => l_scope);

   select convert_session_date_utc(
              p_date => p_date + ts.day_offset
            , p_time_slot => ts.time_slot
          )
    into l_utc_date
    from wmg_time_slots_all_v ts
   where ts.time_slot = p_time_slot;

  logger.log(p_text => '.. l_utc_date: ' || l_utc_date, p_scope => l_scope);
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
  logger.log(p_text => '.. l_epoch: ' || l_epoch, p_scope => l_scope);

  return l_epoch;

exception
  when others then
     logger.log_error(p_text => 'Unexpected error', p_scope => l_scope);
    return 0;
end format_session_date_epoch;






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
    logger.log('START', l_scope);
    logger.log(p_text => '.. p_date: ' || p_date, p_scope => l_scope);
    logger.log(p_text => '.. p_time_slot: ' || p_time_slot, p_scope => l_scope);
    logger.log(p_text => '.. p_timezone: ' || p_timezone, p_scope => l_scope);

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
  logger.log(l_local_date);

  -- add the timezone
  l_local_date := l_local_date  at time zone p_timezone;
  -- get the local user time
  logger.log(l_local_date);

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
    p_output out clob
)
is
  l_scope scope_t := gc_scope_prefix || 'current_tournament';
begin
  logger.log(p_text => 'START', p_scope => l_scope);
  
  select json_object(
           'tournament' value json_object(
               'id' value t.tournament_id
             , 'name' value t.name
             , 'code' value t.code
           )
         , 'sessions' value json_object(
               'id' value t.tournament_session_id
             , 'week' value t.week
             , 'session_date' value format_session_date_utc(t.session_date)
             , 'open_registration_on' value format_session_date_utc(t.open_registration_on)
             , 'close_registration_on' value format_session_date_utc(t.close_registration_on)
             , 'registration_open' value case 
                 when t.open_registration_on is null or t.open_registration_on < localtimestamp
                 then 'true' else 'false'
                 end format json
             , 'available_time_slots' value (
                 select json_arrayagg(
                          json_object(
                              'time_slot' value ts.time_slot
                            , 'day_offset' value ts.day_offset
                            , 'display' value ts.prepared_time_slot
                          ) order by ts.seq
                        )
                   from wmg_time_slots_all_v ts
               )
             , 'courses' value build_courses_json(t.tournament_session_id)
           )
           returning clob
         )
    into p_output
    from (
           select t.id tournament_id
                , t.name
                , t.code
                , s.tournament_session_id
                , s.week
                , s.session_date
                , s.open_registration_on
                , s.close_registration_on
             from wmg_tournaments t
                , wmg_tournament_sessions_v s
            where s.tournament_id = t.id
              and t.current_flag = 'Y'
              and t.active_ind = 'Y'
              and s.session_date + 1 >= trunc(current_timestamp)
              and s.completed_ind = 'N'
            fetch first 1 rows only
         ) t;

  if p_output is null then
    p_output := '{}';
  end if;

  logger.log(p_text => 'END', p_scope => l_scope);
exception
  when others then
    logger.log_error(p_text => sqlerrm, p_scope => l_scope);
    raise;
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
                        , 'room_no' value tp.room_no
                        , 'courses' value build_courses_json(ts.id) format json
                      )
                      order by ts.session_date
                      returning clob
                    )
               from wmg_tournament_players tp
               join wmg_tournament_sessions ts 
                 on tp.tournament_session_id = ts.id
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



end wmg_rest_api;
/