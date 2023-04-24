

PRO TABLES
PRO ----------------------------------------
PRO .. wmg_parameters
@../install/wmg_parameters.sql


PRO VIEWS
PRO ----------------------------------------
PRO .. wmg_tournament_sessions_v
@../views/wmg_tournament_sessions_v.sql


PRO PACKAGES
PRO ----------------------------------------
PRO .. wmg_util.pks
@../packages/wmg_util.pks

PRO .. wmg_util.pkb
@../packages/wmg_util.pkb

PRO DML
PRO ----------------------------------------
PRO .. cleanup old tables
drop table wmg_course_previews2 purge;
drop table wmg_course_previews_err$ purge;

