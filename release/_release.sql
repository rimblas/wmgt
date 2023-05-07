
set feedback off
set verify off


-- PRO APEX DISABLE APP
-- PRO ________________________________________

-- set define &
-- @../apex/apex_disable 200
-- set define off

PRO TABLES
PRO ________________________________________
alter table wmg_tournament_players add no_show_flag                  varchar2(1);
comment on column wmg_tournament_players.no_show_flag is 'Flag players that do not show up';



PRO VIEWS
PRO ________________________________________

PRO .. wmg_tournament_player_v
@../views/wmg_tournament_player_v.sql


PRO PACKAGES
PRO ________________________________________



PRO DML
PRO ________________________________________



PRO DDL
PRO ________________________________________



PRO APEX 
PRO ________________________________________
-- @../apex/pre_apex_install.sql
-- @../apex/f200.sql

