
set feedback off
set verify off


PRO APEX DISABLE APP
PRO ________________________________________

set define &
@../apex/apex_disable 200
set define off


PRO DDL
PRO ________________________________________

alter table wmg_tournament_players rename column no_show_flag to issue_code;
alter table wmg_tournament_players modify issue_code varchar(10); 
comment on column wmg_tournament_players.issue_code is 'Flag players issues: no scores, no show, infraction';


PRO TABLES
PRO ________________________________________

@../install/wmg_issues.sql

PRO .. Add wmg_tournament_players wmg_issues constraint
alter table wmg_tournament_players modify issue_code constraint wmg_tournament_pla_issue_fk 
references wmg_issues(code);


PRO VIEWS
PRO ________________________________________

@../views/wmg_tournament_player_v.sql


PRO PACKAGES
PRO ________________________________________

PRO ../packages/wmg_util.pks
@../packages/wmg_util.pks
PRO ../packages/wmg_util.pkb
@../packages/wmg_util.pkb


PRO DML
PRO ________________________________________

@../data/seed_issues.sql

PRO .. Convert no show to issue_code
update wmg_tournament_players
  set issue_code = 'NOSHOW'
where issue_code = 'Y';


PRO APEX 
PRO ________________________________________
@../apex/pre_apex_install.sql
@../apex/f200.sql

set feedback on
set verify on

