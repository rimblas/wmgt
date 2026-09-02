

--------------------------------------------------------------------------------
--*
--* 
--*
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
declare
  l_value wmg_parameters.value%TYPE; 
  l_cards_import_present number;
  l_fantasy_golf_present number;
begin

  -- we're selecting directly from wmg_parameters because wmg_util.get_param needs 
  -- the "env" package
  
  select value
    into l_value
    from wmg_parameters
   where name_key = 'ENV';

  select count(*)
   into l_cards_import_present
  from  user_tables
  where table_name = 'WMG_CARD_RUNS';

  select count(*)
   into l_fantasy_golf_present
  from  user_tables
  where table_name = 'FGL_LEAGUES';

execute immediate 
'create or replace package env is

wmgt constant boolean := ' || case when l_value = 'WMGT' then 'true' else 'false' end || ';
fhit constant boolean := ' || case when l_value like 'FHIT%' then 'true' else 'false' end || ';
kwt constant boolean := ' || case when l_value = 'KWT' then 'true' else 'false' end || ';

cards constant boolean := ' || case when l_cards_import_present = 1 then 'true' else 'false' end || ';
fgl   constant boolean := ' || case when l_fantasy_golf_present = 1 then 'true' else 'false' end || ';

end env;';
end;
/