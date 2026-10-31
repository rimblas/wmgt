-- Run after compiling packages/wmg_util.pkb in the test schema.
-- Exercise the private rooms() function from the installed package source
-- without changing registrations, assignments, or the package interface.
set serveroutput on
whenever sqlerror exit failure rollback

declare
  l_source varchar2(32767);
  l_collect boolean := false;
begin
  for s in (
    select text
      from user_source
     where name = 'WMG_UTIL'
       and type = 'PACKAGE BODY'
     order by line
  ) loop
    if regexp_like(s.text, '^function rooms\(', 'i') then
      l_collect := true;
    end if;
    if l_collect then
      l_source := l_source || s.text;
      exit when regexp_like(s.text, '^end rooms;', 'i');
    end if;
  end loop;

  if l_source is null then
    raise_application_error(-20001, 'WMG_UTIL.rooms source not found');
  end if;

  execute immediate 'declare
    l_expected sys.odcinumberlist := sys.odcinumberlist(
      0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5
    );
    l_rooms number;
    l_smallest number;
    l_largest number;
    ' || l_source || '
  begin
    if rooms(null) <> 0 then
      raise_application_error(-20002, ''Null player count must need zero rooms'');
    end if;

    for n in 0 .. 15 loop
      if rooms(n, ''3'') <> l_expected(n + 1) then
        raise_application_error(-20003, ''Unexpected room count for '' || n);
      end if;
    end loop;

    for n in 0 .. 1000 loop
      if rooms(n) <> ceil(n / 4)
         or rooms(n, ''4'') <> ceil(n / 4)
         or rooms(n, null) <> ceil(n / 4)
         or rooms(n, ''invalid'') <> ceil(n / 4)
         or rooms(n, ''5'') <> ceil(n / 4) then
        raise_application_error(-20005, ''Default/fallback room count for '' || n);
      end if;
    end loop;

    -- Round-robin assignments must yield only rooms of 3 or 4 for n >= 6.
    -- Also ensure we use the most rooms possible without creating pairs.
    for n in 6 .. 1000 loop
      l_rooms := rooms(n, ''3'');
      l_smallest := trunc(n / l_rooms);
      l_largest := ceil(n / l_rooms);
      if l_smallest < 3 or l_largest > 4
         or trunc(n / (l_rooms + 1)) >= 3 then
        raise_application_error(-20004, ''Invalid distribution for '' || n);
      end if;
    end loop;
    dbms_output.put_line(''PASS: preferences 3/4, default/fallback, null, and distributions 6-1000'');
  end;';
end;
/
