

--------------------------------------------------------------------------------
--*
--* 
--*
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
declare
  l_value wmg_parameters.value%TYPE; 
begin

  -- we're selecting directly from wmg_parameters because wmg_util.get_param needs 
  -- the "env" package
  
  select value
    into l_value
    from wmg_parameters
   where name_key = 'ENV';

execute immediate 
'create or replace package env is

wmgt constant boolean := ' || case when l_value = 'WMGT' then 'true' else 'false' end || ';
fhit constant boolean := ' || case when l_value like 'FHIT%' then 'true' else 'false' end || ';
kwt constant boolean := ' || case when l_value = 'KWT' then 'true' else 'false' end || ';

end env;';
end;
/