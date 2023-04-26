-- *** APEX ***
PROMPT *** APEX Installation ***

set serveroutput on size unlimited;
begin
apex_application_install.set_workspace('WMGT');
  apex_application_install.set_application_id(200);
  apex_application_install.set_schema('WMGT_WSKP');
  -- apex_application_install.generate_offset;
  -- we want the ID to match across workspaces
  apex_application_install.set_offset(0);
end;
/
@@f200.sql
