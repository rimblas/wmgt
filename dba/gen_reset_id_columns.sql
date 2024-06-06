
set feedback off
set timing off
set heading off
set pagesize 100
set linesize 120

spool reset_id_columns.sql
select 'alter table ' || table_name || ' modify ' || column_name || ' generated always as identity restart start with ' 
|| (getmax(table_name, column_name) + 1)
|| ';'
from user_tab_columns
where identity_column = 'YES'
and data_default is not null
/
spool off
