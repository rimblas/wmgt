
set feedback off
set verify off


PRO APEX DISABLE APP
PRO ________________________________________

set define &
@../apex/apex_disable 200
set define off


PRO DDL
PRO ________________________________________

-- Deployed!
-- alter table wmg_tournament_players add points_override                number;
-- comment on column wmg_tournament_players.points_override is 'Override for regular points. Applied at the time of closing.';

alter table wmg_tournament_players add no_scores_flag                 varchar2(1);
comment on column wmg_tournament_players.no_scores_flag is 'Played played but did not submit scores';

alter table wmg_tournament_players add violation_flag                 varchar2(1);
comment on column wmg_tournament_players.violation_flag is 'Played violated the rules';


PRO TABLES
PRO ________________________________________



PRO VIEWS
PRO ________________________________________

@../views/wmg_tournament_player_v.sql


PRO PACKAGES
PRO ________________________________________

@../packages/wmg_util.pks
@../packages/wmg_util.pkb

PRO DML
PRO ________________________________________

-- IMPORTANT Edit app to edit the points_override


PRO APEX 
PRO ________________________________________
@../apex/pre_apex_install.sql
@../apex/f200.sql

