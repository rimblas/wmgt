whenever sqlerror exit failure rollback

declare
begin
  if not env.fhit then
    raise_application_error(
        -20000
      , 'packages/_ins_fhit.sql must only be run in an FHIT schema.'
    );
  end if;
end;
/

PRO . FHIT-ONLY PACKAGE SPECS
PRO .. wmg_leaderboard_util.pks
@@wmg_leaderboard_util.pks

PRO . FHIT-ONLY PACKAGE BODIES
PRO .. wmg_leaderboard_util.pkb
@@wmg_leaderboard_util.pkb
