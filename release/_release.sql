
set feedback off
set verify off


PRO APEX DISABLE APP
PRO ________________________________________

set define &
@../apex/apex_disable 200
set define off

PRO TABLES
PRO ________________________________________

@../install/wmg_tournament_rooms.sql

PRO VIEWS
PRO ________________________________________



PRO PACKAGES
PRO ________________________________________



PRO DML
PRO ________________________________________

insert into wmg_tournament_rooms (
  tournament_session_id
, time_slot
, room_no
)
select distinct tournament_session_id
     , time_slot
     , room_no
  from wmg_tournament_players
 where tournament_session_id = 522
   and active_ind = 'Y'
/


PRO DDL
PRO ________________________________________



PRO APEX 
PRO ________________________________________
@../apex/pre_apex_install.sql
@../apex/f200.sql

