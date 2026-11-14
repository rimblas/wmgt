-- Run after compiling packages/wmg_util.pkb in the test schema.
-- Exercise the actual next-room query without invoking assign_rooms' commit
-- or modifying registrations. Empty slots must preserve the room sequence.
set serveroutput on
whenever sqlerror exit failure rollback

declare
  l_source varchar2(32767);
  l_in_assign_rooms boolean := false;
  l_collect boolean := false;
begin
  for s in (
    select text
      from user_source
     where name = 'WMG_UTIL'
       and type = 'PACKAGE BODY'
     order by line
  ) loop
    if regexp_like(s.text, '^procedure assign_rooms\(', 'i') then
      l_in_assign_rooms := true;
    end if;
    if l_in_assign_rooms and regexp_like(s.text, '^ *select .*max\(room_no\)', 'i') then
      l_collect := true;
    end if;
    if l_collect then
      l_source := l_source || s.text;
      exit when instr(s.text, ';') > 0;
    end if;
    exit when regexp_like(s.text, '^end assign_rooms;', 'i');
  end loop;

  if l_source is null then
    raise_application_error(-20001, 'assign_rooms next-room query not found');
  end if;

  l_source := replace(l_source, 'wmg_tournament_players',
    '(select column_value room_no, 1 tournament_session_id,
             ''test'' time_slot from table(l_assignments))');

  execute immediate 'declare
    l_assignments sys.odcinumberlist := sys.odcinumberlist();
    l_room_no number := 1;
    p_tournament_session_id number := 1;
    type slot_rec is record (time_slot varchar2(10));
    time_slots slot_rec;

    procedure advance_room(p_expected number) is
    begin
      ' || l_source || '
      if l_room_no is null or l_room_no <> p_expected then
        raise_application_error(-20002, ''Expected next room '' || p_expected
          || '', got '' || nvl(to_char(l_room_no), ''NULL''));
      end if;
    end;
  begin
    time_slots.time_slot := ''test'';
    -- Leading and consecutive empty slots must keep room 1 available.
    advance_room(1);
    advance_room(1);
    l_assignments := sys.odcinumberlist(1, 1, 2, 2, 3, 3);
    advance_room(4);
    -- Reproduce an empty middle slot followed by populated slots.
    l_assignments := sys.odcinumberlist();
    advance_room(4);
    advance_room(4);
    l_assignments := sys.odcinumberlist(4, 4, 5, 5);
    advance_room(6);
    l_assignments := sys.odcinumberlist(6, 6);
    advance_room(7);
    -- An empty trailing slot must also preserve the sequence.
    l_assignments := sys.odcinumberlist();
    advance_room(7);
    dbms_output.put_line(''PASS: empty slots preserve the next room number'');
  end;';
end;
/
