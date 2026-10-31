-- Safe to rerun: preserve any existing preference.
insert into wmg_parameters (category, name_key, value, description)
select 'Tournament', 'PREFERRED_ROOM_SIZE', '4',
       'Preferred room size: 4 (default) or 3 (allow 4 to avoid pairs). Applies to future room randomizations.'
  from dual
 where not exists (
   select 1 from wmg_parameters where name_key = 'PREFERRED_ROOM_SIZE'
 );

commit;
