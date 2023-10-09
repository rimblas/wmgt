
set feedback off
set verify off


PRO APEX DISABLE APP
PRO ________________________________________

set define &
@../apex/apex_disable 200
set define off


PRO DDL
PRO ________________________________________


PRO .. Recreate the week format constraint
alter table wmg_rounds drop constraint wmg_rouund_week_ck;

alter table wmg_rounds add constraint wmg_rouund_week_ck check (regexp_like(week, 'S[0-9]+[A-Z]?W[0-9]+'));


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

