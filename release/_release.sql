
set feedback off
set verify off


PRO APEX DISABLE APP
PRO ________________________________________

set define &
@../apex/apex_disable 200
set define off


PRO DDL
PRO ________________________________________


insert into wmg_tournaments (
  id
, code
, name
, prefix_tournament
, prefix_session
, active_ind
)
values (
  0 -- id
, 'WMGT0' -- code
, 'System Reference' -- name
, 'S00' -- prefix_tournament
, 'W' -- prefix_session
, 'N' -- active_ind
);

insert into wmg_tournament_sessions (
  id
, tournament_id
, round_num
, session_date
, week
, completed_ind
)
values (
  0 -- id
, 0 -- tournament_id
, 0 -- round_num
, to_date('01-JAN-2000', 'DD-MON-YYYY') -- session_date
, 'S00W00'-- week
, 'Y' -- completed_ind
);



alter table wmg_rounds
add tournament_session_id          number
                                   constraint wmg_round_tournament_sess_fk
                                   references wmg_tournament_sessions(id);
update wmg_rounds r
set tournament_session_id = (select ts.id from wmg_tournament_sessions ts where ts.week = r.week)
/
alter table wmg_rounds modify tournament_session_id          number not null;

/*
P60_EASY & P60_HARD

select c.code
    from wmg_courses_v c
       , wmg_tournament_courses tc
   where c.course_id = tc.course_id
     and tc.tournament_session_id = :P60_TOURNAMENT_SESSION_ID
     and course_no = 1
*/


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

