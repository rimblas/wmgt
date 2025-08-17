-- Test script for Discord Bot API endpoints
-- This script tests the basic functionality of the Discord Bot API

SET SERVEROUTPUT ON
SET PAGESIZE 0
SET LINESIZE 1000

PROMPT Testing Discord Bot API endpoints...
PROMPT

-- Test 1: Check if current tournament endpoint works
PROMPT Test 1: GET /api/tournaments/current
PROMPT =====================================

declare
  l_clob clob;
begin
  -- Simulate the GET /api/tournaments/current endpoint logic
  select json_object(
    'tournament' value json_object(
      'id' value t.tournament_id,
      'name' value t.name,
      'code' value t.code
    ),
    'sessions' value (
      select json_arrayagg(
        json_object(
          'id' value s.tournament_session_id,
          'week' value s.week,
          'session_date' value to_char(s.session_date, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
          'open_registration_on' value to_char(s.open_registration_on, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
          'close_registration_on' value to_char(s.close_registration_on, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
          'registration_open' value case 
            when current_timestamp between s.open_registration_on and s.close_registration_on 
            then 'true' else 'false' end,
          'available_time_slots' value (
            select json_arrayagg(
              json_object(
                'time_slot' value ts.time_slot,
                'day_offset' value ts.day_offset,
                'display' value ts.prepared_time_slot
              ) order by ts.seq
            )
            from wmg_time_slots_all_v ts
          ),
          'courses' value (
            select json_arrayagg(
              json_object(
                'course_no' value case when tc.course_no = 1 then 1 else 2 end,
                'course_name' value c.name,
                'course_code' value c.code,
                'difficulty' value case when tc.course_no = 1 then 'Easy' else 'Hard' end
              )
            )
            from wmg_tournament_courses tc
            join wmg_courses c on tc.course_id = c.id
            where tc.tournament_session_id = s.tournament_session_id
          )
        ) returning clob
      )
      from wmg_tournament_sessions_v s
      where s.tournament_id = t.tournament_id
        and s.session_date + 1 >= trunc(current_timestamp)
        and s.completed_ind = 'N'
      order by s.session_date
    ) returning clob
  ) into l_clob
  from (
    select t.id tournament_id, t.name, t.code
    from wmg_tournaments t
    where t.current_flag = 'Y'
      and t.active_ind = 'Y'
    fetch first 1 rows only
  ) t;

  if l_clob is null then
    dbms_output.put_line('No current tournament found');
  else
    dbms_output.put_line('Current tournament data:');
    dbms_output.put_line(substr(l_clob, 1, 4000));
    if length(l_clob) > 4000 then
      dbms_output.put_line('... (truncated)');
    end if;
  end if;
exception
  when others then
    dbms_output.put_line('ERROR: ' || sqlerrm);
end;
/

PROMPT
PROMPT Test 2: Check tournament sessions structure
PROMPT ==========================================

select 'Tournament Sessions:' as info from dual;

select t.name as tournament_name,
       ts.week,
       ts.session_date,
       case when current_timestamp between ts.open_registration_on and ts.close_registration_on 
            then 'OPEN' else 'CLOSED' end as registration_status,
       ts.completed_ind
from wmg_tournaments t
join wmg_tournament_sessions ts on t.id = ts.tournament_id
where t.current_flag = 'Y'
  and t.active_ind = 'Y'
  and ts.session_date + 1 >= trunc(current_timestamp)
order by ts.session_date
fetch first 5 rows only;

PROMPT
PROMPT Test 3: Check player structure for Discord integration
PROMPT ====================================================

select 'Sample Players with Discord IDs:' as info from dual;

select player_name,
       account,
       discord_id,
       prefered_tz
from wmg_players_v
where discord_id is not null
fetch first 5 rows only;

PROMPT
PROMPT Test 4: Check tournament courses structure
PROMPT =========================================

select 'Tournament Courses:' as info from dual;

select ts.week,
       tc.course_no,
       c.name as course_name,
       c.code as course_code
from wmg_tournaments t
join wmg_tournament_sessions ts on t.id = ts.tournament_id
join wmg_tournament_courses tc on ts.id = tc.tournament_session_id
join wmg_courses c on tc.course_id = c.id
where t.current_flag = 'Y'
  and t.active_ind = 'Y'
  and ts.session_date + 1 >= trunc(current_timestamp)
order by ts.session_date, tc.course_no
fetch first 10 rows only;

PROMPT
PROMPT Test 5: Show available time slots with day offsets
PROMPT ===================================================

select 'Available time slots:' as info from dual;

select seq,
       time_slot,
       day_offset,
       prepared_time_slot as display
from wmg_time_slots_all_v
order by seq;

PROMPT
PROMPT Testing complete.
PROMPT
PROMPT To test the actual REST endpoints, use a tool like curl or Postman:
PROMPT   curl -X GET "http://your-server/ords/wmgt/api/tournaments/current"
PROMPT