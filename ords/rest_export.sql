set feedback off
spool tournament.sql
rest export tournament
spool off
host echo "/" >> tournament.sql