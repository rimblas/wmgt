
set feedback off
set verify off


PRO APEX DISABLE APP
PRO ________________________________________

set define &
@../apex/apex_disable 200
set define off

PRO TABLES
PRO ________________________________________


PRO VIEWS
PRO ________________________________________

PRO .. wmg_rounds_v.sql
@../views/wmg_rounds_v.sql
PRO .. wmg_tournament_session_points_v.sql
@../views/wmg_tournament_session_points_v.sql


PRO PACKAGES
PRO ________________________________________

PRO .. wmg_util
@../packages/wmg_util.pkb


PRO DML
PRO ________________________________________

PRO .. New Rank updates
@..data/seed_wmg_ranks.sql

PRO .. Update all Amaterur players to the new rank
update wmg_players
    set rank_code = 'AMA'
  where id < 1505
    and rank_code = 'NEW';

delete from wmg_parameters;


PRO DDL
PRO ________________________________________



PRO APEX 
PRO ________________________________________
@../apex/_ins.sql
