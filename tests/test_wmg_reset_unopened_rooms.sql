-- Run in a test schema with an assigned, unopened session.
-- All test changes are rolled back; no randomization/opening is invoked.
set serveroutput on
whenever sqlerror exit failure rollback

declare
  l_session_id wmg_tournament_sessions.id%type;
  l_count number;
begin
  select min(s.id)
    into l_session_id
    from wmg_tournament_sessions s
   where s.rooms_defined_flag = 'Y'
     and nvl(s.rooms_open_flag, 'N') <> 'Y'
     and nvl(s.completed_ind, 'N') <> 'Y'
     and not exists (
       select 1 from wmg_tournament_rooms r
        where r.tournament_session_id = s.id
     );

  if l_session_id is null then
    raise_application_error(-20002, 'Test needs an assigned, unopened session');
  end if;

  savepoint before_room_reset_test;
  wmg_util.reset_unopened_room_assignments(l_session_id);

  select count(*) into l_count
    from wmg_tournament_players
   where tournament_session_id = l_session_id and room_no is not null;
  if l_count <> 0 or wmg_util.rooms_set(l_session_id) <> 'N' then
    raise_application_error(-20003, 'Assignments or room-defined state not cleared');
  end if;
  rollback to before_room_reset_test;

  -- Reject both open and completed sessions without clearing assignments.
  for i in 1 .. 2 loop
    update wmg_tournament_sessions
       set rooms_open_flag = case when i = 1 then 'Y' else null end
         , completed_ind = case when i = 2 then 'Y' else 'N' end
     where id = l_session_id;
    begin
      wmg_util.reset_unopened_room_assignments(l_session_id);
      raise_application_error(-20004, 'Expected reset to be rejected');
    exception
      when others then
        if sqlcode <> -20001 then
          raise;
        end if;
    end;
    rollback to before_room_reset_test;
  end loop;

  dbms_output.put_line('PASS: unopened reset and open/completed guards');
exception
  when others then
    rollback;
    raise;
end;
/
