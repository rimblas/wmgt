
set feedback off
set verify off


PRO APEX DISABLE APP
PRO ________________________________________

set define &
@../apex/apex_disable 200
set define off


PRO DDL
PRO ________________________________________



/*

ELITE

PRO
SEMI
AMA
RISING
NEW
*/

PRO .. Table backup
create table wmg_players_back as select * from wmg_players;

PRO .. add update Ranks
@../data/seed_wmg_ranks.sql


update wmg_players
   set rank_code = 'ELITE'
where rank_code = 'PRO'
/

update wmg_players
   set rank_code = 'PRO'
where rank_code = 'SEMI'
/

update wmg_players
   set rank_code = 'SEMI'
where rank_code = 'RISING'
/


PRO TABLES
PRO ________________________________________



PRO VIEWS
PRO ________________________________________



PRO PACKAGES
PRO ________________________________________



PRO DML
PRO ________________________________________



PRO APEX 
PRO ________________________________________
@../apex/pre_apex_install.sql
@../apex/f200.sql

set feedback on
set verify on

