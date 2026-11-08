-- Run in a DEVELOPMENT database after compiling wmg_rest_api.pkb.
-- Supply an existing non-NEW, non-moderated player's Discord ID, an open
-- session in a season where they have >=3 active NOSHOW or NOSCORE issues,
-- and their Discord username. This exercises the real API rejection path.
-- Usage: @tests/test_registration_attendance.sql DISCORD_ID SESSION_ID USERNAME
set serveroutput on
set verify off
whenever sqlerror exit failure rollback

declare
  l_body clob;
  l_output clob;
  l_result json_object_t;
  l_before clob;
  l_after clob;

  function registrations return clob is
    l_rows clob;
  begin
    select json_arrayagg(
             json_object('id' value tp.id, 'slot' value tp.time_slot,
                         'active' value tp.active_ind)
             order by tp.id returning clob)
      into l_rows
      from wmg_tournament_players tp
      join wmg_players p on p.id = tp.player_id
     where p.discord_id = '&1';
    return nvl(l_rows, '[]');
  end;
begin
  savepoint attendance_test;
  l_before := registrations;
  l_body := json_object(
    'session_id' value to_number('&2'),
    'time_slot' value '22:00',
    'discord_user' value json_object(
      'id' value '&1', 'username' value '&3',
      'global_name' value '&3', 'discriminator' value '0'));

  apex_json.initialize_clob_output;
  wmg_rest_api.handle_registration(l_body);
  l_output := apex_json.get_clob_output;
  l_result := json_object_t.parse(l_output);
  if l_result.get_boolean('success')
     or nvl(l_result.get_string('error_code'), '?') != 'ATTENDANCE_LIMIT_REACHED' then
    raise_application_error(-20001, 'Expected attendance rejection: ' || dbms_lob.substr(l_output, 1000, 1));
  end if;
  l_after := registrations;
  if dbms_lob.compare(l_before, l_after) != 0 then
    raise_application_error(-20002, 'Blocked request changed registrations');
  end if;
  apex_json.free_output;
  rollback to attendance_test;
  dbms_output.put_line('PASS: attendance limit rejected registration without changing registrations');
exception
  when others then
    apex_json.free_output;
    rollback;
    raise;
end;
/
